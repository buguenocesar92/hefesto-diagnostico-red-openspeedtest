#!/usr/bin/env bash
# Pruebas de scripts/coolify-check.sh. Asume bash, jq y docker compose.
#
# Uso: bash tests/coolify-check-test.sh
set -uo pipefail

repo_root="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
cd "$repo_root"

# Cuando el script se corre dentro del repo, project_basename es
# 'hefesto-diagnostico-red-openspeedtest'. Las fixtures incluyen ese
# 'name:' explícito para que el render coincida y no aparezcan falsos
# positivos del check de nombre raíz.
REPO_BASENAME="hefesto-diagnostico-red-openspeedtest"
FIX="$repo_root/tests/fixtures"

FAIL=0
fail() {
    echo "FAIL: $1" >&2
    FAIL=$((FAIL + 1))
}

assert_in() {
    local label="$1"
    local out="$2"
    local needle="$3"
    if [[ "$out" != *"$needle"* ]]; then
        fail "$label: no aparece '$needle' en salida. Salida: $out"
        return
    fi
    echo "ok: $label"
}

assert_not_in() {
    local label="$1"
    local out="$2"
    local needle="$3"
    if [[ "$out" == *"$needle"* ]]; then
        fail "$label: aparece '$needle' en salida. Salida: $out"
        return
    fi
    echo "ok: $label"
}

write_fixture() {
    local name="$1"
    local content="$2"
    mkdir -p "$FIX/$name"
    printf '%s' "$content" > "$FIX/$name/compose.yaml"
}

# run_with <fixture_dir> → ejecuta el script apuntando al compose del fixture.
run_with() {
    local fixture_dir="$1"
    local tmp_script
    tmp_script="$(mktemp)"
    sed "s|compose_files=(compose.yaml)|compose_files=($fixture_dir/compose.yaml)|" \
        "$repo_root/scripts/coolify-check.sh" > "$tmp_script"
    chmod +x "$tmp_script"
    set +e
    bash "$tmp_script" 2>&1
    local code=$?
    set -e
    rm -f "$tmp_script"
    return "$code"
}

rm -rf "$FIX"
mkdir -p "$FIX"

# Fixture A: ${VAR} no presente en el env hardcoded del script. Con el
# sufijo ':?mensaje', render falla si el script no auto-extrae la variable.
write_fixture "extrae-var" "name: $REPO_BASENAME
services:
  app:
    image: example/app:1
    environment:
      NUEVA_VAR: \${NUEVA_VAR:?requerida}
  gateway:
    image: caddy:2-alpine
    environment:
      U: \${BASIC_AUTH_USER}
"

# Fixture B: render debe fallar y el script debe decirlo. Invalid YAML
# produce un error real de parseo que no se puede enmascarar.
write_fixture "error-render" "name: $REPO_BASENAME
services:
  app:
    image: example/app:1
    environment:
      BAD: [
este compose no es YAML válido
"

# Fixture C: render sin services produce 'networks: null' y rompe
# .networks | keys[] si el script no usa null-safe.
write_fixture "sin-networks" "name: $REPO_BASENAME
services: {}
"

# Fixture D: compose original (2b9db73) tiene 'name:' distinto del actual
# y debe detectarlo.
TMP_D="$(mktemp -d)"
git -C "$repo_root" show 2b9db73:compose.yaml > "$TMP_D/compose.yaml"

# Assertions.
out="$(run_with "$FIX/extrae-var")"; assert_in "extrae-VAR-del-compose" "$out" "coolify-check: OK"

out="$(run_with "$FIX/error-render")"; assert_in "muestra-error-de-render" "$out" "no renderiza"

out="$(run_with "$FIX/sin-networks")"; assert_not_in "sin-networks-no-revienta" "$out" "null (null) has no keys"

# Para el original no podemos usar la FIX porque su YAML tiene 'name:'
# hardcodeado distinto y queremos comprobarlo. Generamos un script
# modificado temporalmente que use $TMP_D.
tmp_script="$(mktemp)"
sed "s|compose_files=(compose.yaml)|compose_files=($TMP_D/compose.yaml)|" \
    "$repo_root/scripts/coolify-check.sh" > "$tmp_script"
chmod +x "$tmp_script"
set +e
out="$(cd "$repo_root" && bash "$tmp_script" 2>&1)"
set -e
rm -f "$tmp_script" && rm -rf "$TMP_D"

assert_in "detecta-name-en-compose-original" "$out" "nombre de proyecto raíz fijo"

if [[ "$FAIL" -gt 0 ]]; then
    echo "FAIL: $FAIL prueba(s) fallaron" >&2
    exit 1
fi
echo "PASS: todas las pruebas"
