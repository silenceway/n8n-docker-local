#!/bin/bash

# --- Configuración ---
N8N_CONTAINER_NAME="n8nn"
N8N_LOCAL_PORT="5678"
DOCKER_NETWORK_NAME="n8n_network"
TZ_SETTING="America/Bogota" # Cambia esto a tu zona horaria

# 1. Detener y eliminar el contenedor n8n anterior si existe
echo "Deteniendo y eliminando contenedor n8n anterior ($N8N_CONTAINER_NAME)..."
docker stop $N8N_CONTAINER_NAME > /dev/null 2>&1
docker rm $N8N_CONTAINER_NAME > /dev/null 2>&1

# 2. Iniciar cloudflared en segundo plano y capturar la URL dinámica
echo "Iniciando túnel de Cloudflare y capturando URL dinámica..."

# Ejecutamos cloudflared y redirigimos su salida a un archivo temporal mientras esperamos la URL.
cloudflared tunnel --url http://localhost:$N8N_LOCAL_PORT > cloudflare_log.txt 2>&1 &

# Capturamos el ID del proceso (PID) para poder cerrarlo más tarde
CLOUDFLARED_PID=$!

# Esperamos un momento y luego buscamos la línea que contiene la URL pública
sleep 5
DYNAMIC_URL=$(grep -o "https://[-a-zA-Z0-9]*\.trycloudflare\.com" cloudflare_log.txt)

if [ -z "$DYNAMIC_URL" ]; then
    echo "Error: No se pudo capturar la URL dinámica. Revisa cloudflare_log.txt."
    kill $CLOUDFLARED_PID
    exit 1
fi

echo "URL dinámica capturada: $DYNAMIC_URL"

# 3. Iniciar el contenedor n8n con la URL dinámica como variable de entorno
echo "Iniciando contenedor n8n con WEBHOOK_URL=$DYNAMIC_URL..."

docker run -d --name $N8N_CONTAINER_NAME \
  --network $DOCKER_NETWORK_NAME \
  -p $N8N_LOCAL_PORT:$N8N_LOCAL_PORT \
  -e WEBHOOK_URL=$DYNAMIC_URL \
  -e N8N_PROTOCOL=https \
  -e TZ=$TZ_SETTING \
  n8nio/n8n:latest

if [ $? -eq 0 ]; then
    echo "n8n iniciado exitosamente y conectado a $DYNAMIC_URL"
else
    echo "Error al iniciar el contenedor Docker."
    kill $CLOUDFLARED_PID
    exit 1
fi

# Limpieza
rm cloudflare_log.txt
echo "Proceso completado. Tu instancia está accesible en $DYNAMIC_URL"

# NOTA: El proceso de cloudflared seguirá corriendo en tu terminal hasta que lo mates manualmente (Ctrl+C).

