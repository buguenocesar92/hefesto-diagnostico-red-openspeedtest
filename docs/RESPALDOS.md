# Configuración y recuperación
La aplicación no almacena un historial central de pruebas. No hay base de datos ni datos de negocio en un volumen del kit. Las mediciones del navegador y los informes guardados fuera del proyecto necesitan respaldo independiente.

`python3 scripts/backup.py`

Copia .env, Compose y archivos de Caddy a backups/FECHA, modo privado. Solo genera manifest completed al terminar. No detiene servicios porque no copia una base de datos mutable. Ejecutar cuando no se estén editando archivos de configuración; este procedimiento no ofrece una instantánea atómica frente a ediciones concurrentes.

`python3 scripts/check_backup.py backups/FECHA`

Verifica producto, versión, lista exacta, hashes y que las rutas correspondan a archivos regulares dentro de la copia. Los hashes detectan corrupción accidental, no autentican una copia frente a quien pueda modificar también el manifiesto. La copia incluye hash de acceso: cifrar y guardar fuera del servidor.

Recuperar configuración en carpeta que NO exista:

`python3 scripts/restore_config.py /ruta/respaldo /ruta/carpeta-nueva`

El script rechaza carpetas existentes y no cambia ni inicia ningún servicio. Revisar los archivos recuperados y usarlos con el mismo kit e imagen en un servidor de ensayo. Rotar acceso si la copia pudiera estar comprometida. El respaldo no incluye certificados del proxy, DNS, imagen Docker exportada ni configuración global de Coolify.

Para actualizar, revisar fuentes/registro, elegir nueva versión y digest, respaldar y probar en entorno separado. Conservar la referencia anterior para revertir. No asumir que latest sigue apuntando al mismo contenido: el digest del kit fija la imagen que se descarga.
