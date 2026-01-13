# Configuración de túnel local de Cloudflare para N8N

Este repositorio contiene los archivos de configuración y scripts para integrar de forma fluida una instancia local de n8n usando un túnel seguro de Cloudflare para exponerla, todo gestionado con Docker Compose.

## Características

- Entorno dockerizado: Ejecuta n8n y el conector de Cloudflare en contenedores aislados.
- Túnel seguro: Expone la instancia local de n8n de forma segura vía Cloudflare sin abrir puertos en el firewall local.
- Datos persistentes: Usa volúmenes de Docker o montajes bind para asegurar que tus workflows y credenciales de n8n nunca se pierdan.
- Configuración automatizada: Usa docker compose para levantar todo el entorno con un solo comando.

## Primeros pasos

### 1. Clonar el repositorio

Primero, clona este repositorio en tu máquina local usando Git:

```bash
git clone https://github.com/silenceway/n8n-docker-local.git
cd n8n-docker-local
```

Usa el código con precaución.

### 2. Requisitos previos

Antes de empezar, asegúrate de tener lo siguiente:

1. Docker Desktop instalado: Asegura que los comandos docker y docker compose estén disponibles.
2. (Opcional) Una cuenta y dominio en Cloudflare: Debes poseer un dominio y tenerlo gestionado por Cloudflare DNS.

### Opción A: Túnel persistente (recomendado)

Este es el método más estable. Utiliza una URL fija (por ejemplo, https://n8n.tudominio.com) que es ideal para webhooks persistentes.

1. Configuración en Cloudflare (interfaz web)

- Ve al Dashboard de Cloudflare Zero Trust > Networks > Tunnels.
- Crea un nuevo túnel (por ejemplo, n8n-tunnel).
- Copia tu TUNNEL_TOKEN que aparece en la pantalla de configuración.
- En la pestaña Public Hostnames, configura tu dominio:
  Subdominio: n8n
  Dominio: tudominio.com
  Tipo de servicio: HTTP
  URL: http://n8nn:5678 (Este es el nombre del servicio Docker interno)

2. Configurar el archivo docker-compose.yml

Abre el archivo docker-compose.yml en el repositorio clonado y reemplaza los valores de marcador de posición (<...>):

```yaml
# ... (contenido del archivo del repo) ...
    environment:
      # --- REEMPLAZA ESTOS VALORES ---
      WEBHOOK_URL: https://n8n.tudominio.com 
      N8N_PROTOCOL: https
      TZ: America/Bogota # Tu zona horaria
      # ...
    environment:
      # --- REEMPLAZA CON TU TOKEN DEL PASO 1.3 ---
      TUNNEL_TOKEN: <YOUR_CLOUDFLARE_TUNNEL_TOKEN>
# ...
```

Usa el código con precaución.

3. Ejecutar la configuración

- Asegúrate de que la red de Docker exista (solo es necesario una vez):

```bash
docker network create n8n_network
```

Usa el código con precaución.

- Inicia los servicios usando el archivo docker-compose.yml en la carpeta del repositorio:

```bash
docker compose up -d
```

Usa el código con precaución.

Tu instancia n8n ahora está disponible en https://n8n.tudominio.com.

### Opción B: Túnel dinámico (URL temporal)

Esta opción usa URLs temporales (*.trycloudflare.com). El repositorio incluye scripts para automatizar la inyección de la URL dinámica.

Revisa el archivo docker-compose-dynamic.yml y la configuración.
Usa el script apropiado para tu SO (start_dynamic.sh para Linux/macOS/WSL o Start-n8nDynamic.ps1 para PowerShell en Windows) para orquestar el proceso de arranque.
Consulta los comentarios dentro de esos archivos de script para instrucciones de ejecución.

Si PowerShell muestra un error por scripts no firmados, puedes usar:

```powershell
Unblock-File -Path .\Start-n8nDynamic.ps1
```
