# Requires PowerShell 5.1 or higher (standard en Windows 10/11)
# Asegúrate de que docker desktop esté corriendo y 'docker compose' funcione en tu terminal.

$DockerComposeFile = "docker-compose-dynamic.yml"
$N8NContainerName = "n8n"
$DockerNetworkName = "n8n_network"
$N8NLocalPort = "5678"

Write-Host "Verificando/Creando red Docker: $DockerNetworkName"
docker network inspect $DockerNetworkName | Out-Null
if ($LASTEXITCODE -ne 0) {
    docker network create $DockerNetworkName
}

# 1. Levantar solo el servicio n8n
Write-Host "Levantando contenedor n8n..."
docker compose -f $DockerComposeFile up -d n8n

# 2. Iniciar el túnel de Cloudflare y capturar la URL dinámica
Write-Host "Iniciando túnel de Cloudflare y capturando URL dinámica..."

# Ejecutamos el servicio de túnel y capturamos la salida en una variable temporal
# docker compose run --rm ejecuta el servicio y luego lo elimina
$TunnelOutput = docker compose -f $DockerComposeFile run --rm cloudflare_tunnel

# Usamos expresiones regulares para extraer la URL
$Regex = "https://[-a-zA-Z0-9]*\.trycloudflare\.com"
$DynamicURL = $TunnelOutput | Select-String -Pattern $Regex | ForEach-Object { $_.Matches.Value } | Select-Object -First 1

if ([string]::IsNullOrEmpty($DynamicURL)) {
    Write-Error "Error: No se pudo capturar la URL dinámica. Deteniendo servicios."
    docker compose -f $DockerComposeFile down
    exit 1
}

Write-Host "URL dinámica capturada: $DynamicURL"

# 3. Recrear el contenedor n8n con la URL correcta (método robusto)
Write-Host "Deteniendo y recreando contenedor n8n con la URL correcta..."

docker stop $N8NContainerName | Out-Null
docker rm $N8NContainerName | Out-Null

docker run -d --name $N8NContainerName `
  --network $DockerNetworkName `
  -p "$N8NLocalPort:$N8NLocalPort" `
  -e WEBHOOK_URL=$DynamicURL `
  -e N8N_PROTOCOL=https `
  -e TZ="America/Bogota" `
  n8nio/n8n:latest

if ($LASTEXITCODE -eq 0) {
    Write-Host "n8n iniciado exitosamente y accesible en: $DynamicURL"
} else {
    Write-Error "Error al iniciar el contenedor Docker con la URL dinámica."
    exit 1
}

