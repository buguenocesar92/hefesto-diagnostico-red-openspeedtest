#!/usr/bin/env bash
# Verifica que los compose del contrato cumplen los puntos 1 y 2 del contrato
# común de Coolify (MVP Hefesto). No revisa compose.bootstrap.yaml: ese es de
# uso local y queda fuera del contrato (punto 7 del plan).
#
# Salida 0 si pasa; 1 con detalle si falla. Pensado para correr antes de
# hacer push a la rama coolify.
#
# Decisión: el chequeo de 'name:' raíz y de redes/volúmenes se hace con un
# render sin --project-name y se compara contra el basename del repo. Si el
# render los asigna derivados (basename + '_default', etc.), Coolify puede
# imponer el project-name; si vienen fijos desde el YAML, no.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

compose_files=(compose.yaml)

tmp_env="$(mktemp)"
tmp_stderr="$(mktemp)"
trap 'rm -f "$tmp_env" "$tmp_stderr"' EXIT

# Extrae las variables ${VAR} de los compose del contrato y vuelca un valor
# ficticio no secreto por cada una. Las que parecen HOST/URL reciben
# 'https://ejemplo.invalid'. Así, agregar una ${VAR} al compose no rompe el
# render del script. El '|| true' evita que 'set -e' mate el script cuando
# el grep no encuentra ninguna ${VAR}.
{
    grep -ohE '\$\{[A-Za-z_][A-Za-z0-9_]*' "${compose_files[@]}" 2>/dev/null \
        | sed 's/^\${//' \
        | sort -u \
        | { while IFS= read -r v; do
                [[ -z "$v" ]] && continue
                case "$v" in
                    *HOST*|*URL*)
                        printf '%s=https://ejemplo.invalid\n' "$v"
                        ;;
                    *)
                        printf '%s=x123%s%s\n' "$v" "$RANDOM" "$RANDOM"
                        ;;
                esac
            done; } || true
} > "$tmp_env"

errors=0
fail() {
    echo "coolify-check: $1" >&2
    errors=$((errors + 1))
}

project_basename="$(basename "$repo_root")"

for compose_file in "${compose_files[@]}"; do
    if [[ ! -f "$compose_file" ]]; then
        fail "$compose_file: falta el archivo"
        continue
    fi

    # Render con --project-directory (paths relativos como ./ops se
    # resuelven contra el repo) y sin --project-name (deja que compose
    # use el basename del proyecto o el 'name:' del YAML). stderr va a
    # un archivo aparte: si lo mezclamos con stdout, las advertencias
    # de Docker corrompen el JSON que jq espera.
    if ! r="$(docker compose --project-directory "$repo_root" \
                -f "$compose_file" \
                --env-file "$tmp_env" \
                config --format json 2>"$tmp_stderr")"; then
        fail "$compose_file: no renderiza: $(tr '\n' ' ' <"$tmp_stderr")"
        continue
    fi

    # Punto 2: nombre de proyecto raíz fijo.
    name_in_render="$(jq -r '.name // ""' <<<"$r")"
    if [[ -n "$name_in_render" && "$name_in_render" != "$project_basename" ]]; then
        fail "$compose_file: nombre de proyecto raíz fijo ('$name_in_render'); quítalo del compose"
    fi

    # Punto 1: revisar servicios sin profiles.
    while IFS= read -r svc; do
        [[ -z "$svc" ]] && continue
        svc_block="$(jq -c ".services[\"$svc\"]" <<<"$r")"
        profiles="$(jq -r '.profiles // [] | length' <<<"$svc_block")"
        if [[ "$profiles" != "0" ]]; then
            continue
        fi

        if [[ "$(jq -r '.ports // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: expone 'ports:' (Traefik ya publica)"
        fi
        if [[ "$(jq -r '.container_name // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: usa 'container_name:' fijo"
        fi
        if [[ "$(jq -r '.privileged // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: usa 'privileged'"
        fi
        if [[ "$(jq -r '.cap_add // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: usa 'cap_add'"
        fi
        if [[ "$(jq -r '.devices // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: usa 'devices'"
        fi

        nm="$(jq -r '.network_mode // null' <<<"$svc_block")"
        if [[ "$nm" != "null" ]]; then
            fail "$compose_file/$svc: usa 'network_mode: $nm'"
        fi
        if [[ "$(jq -r '.pid // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: usa 'pid'"
        fi
        if [[ "$(jq -r '.ipc // null' <<<"$svc_block")" != "null" ]]; then
            fail "$compose_file/$svc: usa 'ipc'"
        fi

        sec_opt="$(jq -r '.security_opt // [] | .[]' <<<"$svc_block" 2>/dev/null || true)"
        if grep -q 'unconfined' <<<"$sec_opt"; then
            fail "$compose_file/$svc: usa 'security_opt: unconfined'"
        fi

        # Binds fuera del repo o que monten docker.sock.
        while IFS= read -r vol; do
            [[ -z "$vol" ]] && continue
            v_type="$(jq -r '.type // "null"' <<<"$vol")"
            v_src="$(jq -r '.source // "null"' <<<"$vol")"
            if [[ "$v_type" == "bind" ]]; then
                case "$v_src" in
                    *docker.sock)
                        fail "$compose_file/$svc: monta docker.sock"
                        ;;
                    /*)
                        case "$v_src" in
                            "$repo_root"/*) ;;
                            *)
                                fail "$compose_file/$svc: bind fuera del repo: $v_src"
                                ;;
                        esac
                        ;;
                esac
            fi
        done < <(jq -c '.volumes // [] | .[]' <<<"$svc_block")
    done < <(jq -r '.services | keys[]' <<<"$r")

    # Punto 2: redes con nombre fijo. Null-safe: un render sin networks
    # (p. ej. services: {}) devuelve 'networks: null' y rompe keys[].
    while IFS= read -r net; do
        [[ -z "$net" ]] && continue
        n_in_render="$(jq -r ".networks[\"$net\"].name // \"\"" <<<"$r")"
        expected="${project_basename}_${net}"
        if [[ -n "$n_in_render" && "$n_in_render" != "$expected" ]]; then
            fail "$compose_file: red '$net' con nombre fijo ('$n_in_render')"
        fi
    done < <(jq -r '.networks // {} | keys[]' <<<"$r")

    # Punto 2: volúmenes con nombre fijo.
    while IFS= read -r vol; do
        [[ -z "$vol" ]] && continue
        n_in_render="$(jq -r ".volumes[\"$vol\"].name // \"\"" <<<"$r")"
        expected="${project_basename}_${vol}"
        if [[ -n "$n_in_render" && "$n_in_render" != "$expected" ]]; then
            fail "$compose_file: volumen '$vol' con nombre fijo ('$n_in_render')"
        fi
    done < <(jq -r '.volumes // {} | keys[]' <<<"$r" 2>/dev/null || true)
done

if [[ $errors -gt 0 ]]; then
    echo "coolify-check: $errors error(es)" >&2
    exit 1
fi

echo "coolify-check: OK"
