#!/bin/sh
set -eu
printf '%s' "$BASIC_AUTH_USER" | grep -Eq '^[A-Za-z0-9_-]{3,40}$' || { echo 'Usuario invalido' >&2; exit 1; }
printf '%s' "$BASIC_AUTH_HASH" | grep -Eq '^\$2[aby]\$12\$[./A-Za-z0-9]{53}$' || { echo 'Configurar bcrypt cost 12' >&2; exit 1; }
exec caddy run --config /ops/Caddyfile --adapter caddyfile
