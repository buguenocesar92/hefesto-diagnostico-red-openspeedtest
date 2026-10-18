# Hefesto Diagnóstico de Red · OpenSpeedTest
Kit de despliegue para medir velocidad de bajada/subida y latencia entre un navegador y un servidor propio. Permite apoyar diagnósticos de red y comparar puestos o conexiones; no reemplaza monitoreo de disponibilidad como Uptime Kuma.

## Stack
OpenSpeedTest oficial v2.0.6 fijado por digest y Caddy como puerta de acceso. Aplicación estática con servidor nativo; no utiliza PostgreSQL, Supabase ni cuentas de usuario en una base de datos. La autenticación Basic compartida se configura con hash bcrypt en .env. No hay historial central de mediciones ni portal multicliente.

Incluye Compose para Coolify, acceso protegido en todos los endpoints, configuración para cargas de hasta 40 MB en el gateway, plantilla JSON y generador de informe Markdown, respaldo de configuración y checklist de aceptación. No contiene una UI ficticia ni resultados medidos durante la preparación.

## Inicio
1. Leer docs/INSTALACION.md. Generar hash bcrypt y ejecutar `python3 scripts/configure.py`.
2. `docker compose config --quiet`
3. Para acceso de prueba: `docker compose -f compose.yaml -f compose.bootstrap.yaml up -d gateway`.
4. Acceder mediante túnel SSH según guía; esto comprueba la interfaz, no da una medición representativa del enlace normal.
5. Retirar bootstrap y configurar HTTPS en Coolify hacia gateway:8080. No publicar app:3000 ni app:3001.
6. Completar docs/ACEPTACION.md y el procedimiento de medición.

## Informes
Copiar ejemplos/mediciones-demo.json y registrar resultados reales manualmente, indicando demo=false únicamente si son mediciones reales. Ejecutar:

`python3 scripts/informe.py mediciones.json informe-nuevo.md`

El generador calcula medianas y no sobrescribe un archivo existente. No captura resultados automáticamente del navegador. El ejemplo incluido es ficticio y queda marcado como demostración.

## Estado
Kit preparado y comprobado localmente. No se ejecutó Docker, Nginx, Caddy, prueba de velocidad real ni proxy de Coolify. La aceptación depende del despliegue y las pruebas descritas. El ZIP contiene configuración y scripts propios; la aplicación se obtiene mediante la imagen original, no incluye su código completo.

## Despliegue en Coolify (MVP Hefesto)

Coolify publica la app bajo el dominio configurado y termina TLS con su Traefik; este compose enruta el dominio al servicio `gateway`, puerto `8080`. La red por defecto queda libre para que Coolify inyecte la suya; `app` queda en una red interna `backend` (sin salida a internet), y `gateway` la comparte con `default` para llegar a `app:3000`. No requiere base de datos, SMTP ni endpoints extra.

Variables de entorno obligatorias:

| Variable | Uso | Notas |
| --- | --- | --- |
| `BASIC_AUTH_USER` | Usuario para Basic Auth en el gateway | 3–40 caracteres `[A-Za-z0-9_-]` |
| `BASIC_AUTH_HASH` | Hash bcrypt cost 12 del usuario | Formato `$2[aby]$12$...` (53 caracteres de salt+hash tras `$2a$12$`). En Coolify, los `$` se escapan como `$$` para que no se interpreten como variable (ej.: `$$2a$$12$$...`) |

Antes de hacer push, ejecutar `bash scripts/coolify-check.sh` para validar que el compose cumple el contrato de Coolify (sin `ports:`, sin `name:` raíz, etc.).
