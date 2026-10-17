# Procedimiento de diagnóstico
## Qué mide
El trayecto entre navegador y servidor, incluyendo dispositivo, enlace local, Wi-Fi/cable, router, VPN si existe, ISP, red del VPS, TLS y proxies. No certifica por sí solo el ancho de banda contratado, no separa cada tramo y no prueba automáticamente que la falla sea del proveedor.

## Sesión de diagnóstico
1. Elegir alcance: servidor en la LAN para estudiar el enlace local, o servidor remoto para el trayecto hacia ese punto. Dejarlo registrado.
2. Registrar equipo, navegador, servidor, ubicación, fecha/hora, tipo de conexión, VPN/proxy y otros consumos de red.
3. Hacer al menos tres pruebas en condiciones comparables. Comenzar con un equipo por vez y observar CPU/interfaz del servidor.
4. Repetir por cable y por Wi-Fi si el objetivo es comparar ambos, manteniendo el resto de condiciones.
5. Revisar medianas, dispersión y contexto. Una velocidad mayor que el límite físico del enlace sugiere caché, respuesta anticipada o configuración defectuosa; no usar ese resultado comercialmente.
6. Registrar resultados manualmente en JSON y generar informe. No confundir los datos demo con resultados capturados.

La latencia observada por el navegador no es necesariamente idéntica a ping ICMP. No se anuncia medición de pérdida de paquetes, jitter certificado, auditoría Wi-Fi de canales ni pruebas iperf: no están implementadas por este kit.

## Informes
Ejecutar el generador con entrada JSON de 3 a 100 pruebas. Debe contener demo (booleano), datos de contexto y pruebas con bajada_mbps, subida_mbps y latencia_ms. Rechaza valores negativos, NaN e infinitos. Los datos los declara el operador; no hay firma ni evidencia automática del origen.

Guardar JSON e informe en una carpeta de cada cliente, con control de acceso y política de respaldo propia. El backup de configuración del kit NO incluye informes externos ni resultados del navegador. El ejemplo es ficticio, sus medianas no representan desempeño del sistema.

## Servicio comercial
Ofrecer instalación del punto de prueba, diagnóstico de oficina, comparativas antes/después y seguimiento periódico con informe. Presupuestar visita, configuración, análisis y soporte según alcance, sin prometer un porcentaje de mejora.

No exponer una prueba pública ilimitada: cada ejecución puede consumir tráfico considerable y recursos del VPS. La puerta Basic es compartida, no es un sistema de cuotas, facturación ni identidades individuales. Para clientes independientes, usar instancias o accesos separados y controlar sesiones. Este kit no instala una pasarela de cobro ni un limitador de ancho de banda.

## Odoo y otras plataformas
Adjuntar el informe Markdown o su conversión revisada a la tarea/cliente correspondiente. No se incluye exportación automática a Odoo, base Supabase, API CRUD de informes ni integración n8n. Para incorporarlas habría que implementar autenticación, almacenamiento y permisos propios, fuera del alcance actual.
