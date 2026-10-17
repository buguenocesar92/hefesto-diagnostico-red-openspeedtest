# Checklist en el servidor
Registrar fecha, operador y evidencias. Nada de esta lista se considera ejecutado durante la preparación local.

- Docker Compose válido, imágenes disponibles para la arquitectura y healthcheck de app estable.
- Revisar versión, imagen y dependencias antes de producción; no dar por realizado un escaneo que no se ejecutó.
- Sin Basic Auth, tanto / como /downloading y /upload rechazan con 401. Contraseña incorrecta también.
- Con acceso correcto se carga la interfaz original y una prueba completa realiza bajada/subida sin errores 413, 502 o timeout.
- Verificar que todos los proxies permiten al menos 35 MB y que no hay caché, compresión del tráfico de prueba ni CDN inadvertida.
- Comprobar en herramientas de red del navegador que subida transfiere realmente los datos y no se contabiliza una respuesta anticipada. Comparar contra capacidad física conocida y observar tráfico real de la interfaz del servidor; una cifra plausible no es evidencia suficiente por sí sola.
- Comparar con una medición de referencia bajo condiciones controladas. Probar primero un cliente por vez; no atribuir al proveedor un cuello de botella de CPU/proxy.
- Confirmar que puertos 3000/3001 del motor no son públicos, 8119 no permanece expuesto y HTTPS está vigente.
- Reiniciar conserva configuración de acceso; no se espera historial de mediciones porque no está implementado.
- Generar informe demo y comprobar su marca de demostración; cargar datos reales de una sesión y revisar medianas.
- Respaldar configuración, verificarla y recuperarla en carpeta nueva. Probar copia alterada y destino existente: ambos deben rechazarse.

No anunciar servicio aceptado hasta completar las pruebas de acceso, carga real y coherencia de medición.
