#!/bin/bash

DOCKER_COMPOSE_FILE="docker-compose-dynamic.yml"
N8N_CONTAINER_NAME="n8n"

# Asegurarse de que la red exista
docker network create n8n_network > /dev/null 2>&1

# 1. Levantar solo el servicio n8n inicialmente (sin la URL configurada)
echo "Levantando contenedor n8n..."
docker compose -f $DOCKER_COMPOSE_FILE up -d n8n

# 2. Iniciar el túnel de Cloudflare en un nuevo contenedor y capturar la URL
echo "Iniciando túnel de Cloudflare y capturando URL dinámica..."

# Ejecutamos el servicio de túnel usando 'docker-compose run' para obtener la salida directamente
# El comando 'grep' filtra la URL de la salida del log
DYNAMIC_URL=$(docker compose -f $DOCKER_COMPOSE_FILE run --rm cloudflare_tunnel | grep -o "https://[-a-zA-Z0-9]*\.trycloudflare\.com" | head -n 1)

if [ -z "$DYNAMIC_URL" ]; then
    echo "Error: No se pudo capturar la URL dinámica. Deteniendo servicios."
    docker compose -f $DOCKER_COMPOSE_FILE down
    exit 1
fi

echo "URL dinámica capturada: $DYNAMIC_URL"

# 3. Inyectar la URL en el contenedor n8n existente y reiniciarlo
echo "Actualizando WEBHOOK_URL en el contenedor n8n y reiniciando..."

# Usamos 'docker exec' para entrar al contenedor y cambiar la variable, luego reiniciar el servicio internamente
docker exec -it $N8N_CONTAINER_NAME bash -c "export WEBHOOK_URL=$DYNAMIC_URL && n8n restart"

# NOTA: El comando 'n8n restart' dentro del contenedor a veces puede no funcionar perfectamente dependiendo de cómo se inició el proceso inicial. 
# La forma más segura es detener y recrear el contenedor N8N con la variable correcta.

# Forma alternativa y más robusta para el paso 3 y 4: Recrear n8n
echo "Deteniendo y recreando contenedor n8n con la URL correcta..."
docker stop $N8N_CONTAINER_NAME
docker rm $N8N_CONTAINER_NAME

docker run -d --name $N8N_CONTAINER_NAME \
  --network $DOCKER_NETWORK_NAME \
  -p 5678:5678 \
  -e WEBHOOK_URL=$DYNAMIC_URL \
  -e N8N_PROTOCOL=https \
  -e TZ=America/Bogota \
  n8nio/n8n:latest

echo "n8n iniciado exitosamente en $DYNAMIC_URL"

