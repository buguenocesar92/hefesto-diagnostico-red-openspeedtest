# Instalación y proxy
Requisitos: Docker Compose v2, Python 3.11+ para scripts y VPS/equipo con interfaz y recursos superiores al caudal que se desea evaluar. Para uso ligero pueden servir 1 vCPU y 512 MB–1 GB RAM, pero no se ha medido capacidad en este entorno. TLS, proxy, NIC, CPU y concurrencia pueden limitar el resultado.

## Acceso
Generar hash bcrypt cost 12 con contraseña solicitada interactivamente:

`docker run --rm -it caddy:2-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f caddy hash-password --algorithm bcrypt --bcrypt-cost 12`

Ejecutar `python3 scripts/configure.py`, indicar usuario y pegar el hash. Guarda .env modo 0600, sin contraseña en claro y sin sobrescribir archivos previos. El hash queda entre comillas simples para preservar $. No versionar .env. Coolify debe recibir el valor literal, sin comillas añadidas al valor si su interfaz ya maneja secretos.

## Bootstrap
Después de iniciar con el override bootstrap, desde tu equipo:

`ssh -N -L 8119:127.0.0.1:8119 usuario@servidor`

Abrir http://localhost:8119. Solo acceso por túnel en equipo de confianza, no HTTP público. Una prueba ejecutada por ese túnel incluye SSH y no debe compararse como si midiera una conexión directa al servidor.

Retirar con `docker compose -f compose.yaml -f compose.bootstrap.yaml down`, sin -v. Iniciar después solo compose.yaml para eliminar el puerto temporal.

## Coolify y TLS
Importar repositorio privado con compose.yaml, mantener ops y variables. Asignar dominio HTTPS únicamente a gateway, puerto interno 8080. No exponer puertos 3000/3001 del motor: omitiría Basic Auth. TLS corresponde al proxy de Coolify; no se activa Let's Encrypt del contenedor original.

La red Compose se marca internal: la aplicación no necesita salida para medir. Coolify debe conectar gateway a su red de proxy según su configuración habitual. Verificar que el proxy realmente alcanza gateway; no publicar app para resolverlo. Si el proxy añade una segunda red a gateway, esa conexión limita el alcance de la afirmación de aislamiento: revisar egress del entorno si se requiere bloqueo completo.

El gateway permite 40 MB por petición; el servidor original admite 35 MB. Todo proxy intermedio debe permitir al menos 35 MB y timeouts suficientes para enlaces lentos. No activar middleware de compresión, caché, CDN o buffering completo que distorsione la prueba. Caddy usa HTTP/1.1 hacia el motor y no comprime el tráfico de prueba. Esto no garantiza que otros intermediarios estén bien configurados: comprobar descarga y carga de extremo a extremo.

Usar subdominio dedicado sin proxy CDN cuando se busque medir directamente el VPS, con HTTPS válido y acceso restringido. Si se prueba pasando por una CDN, registrar que el resultado incorpora esa ruta. No cambiar DNS o servicios externos como parte de este kit sin autorización.

## Versiones
Se fija openspeedtest/latest:v2.0.6 por digest. La etiqueta tiene fecha de publicación de enero de 2025 en el registro consultado; no se presume que su Nginx base esté actualizado. Antes de producción revisar imagen y dependencias con el proceso de análisis de vulnerabilidades del operador. El kit no incluye un escaneo realizado ni certificación de seguridad. Conservar entrypoint/usuario nativos: no se sustituyen ni se fuerzan permisos que puedan romper su inicialización.
