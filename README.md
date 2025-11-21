# N8N Cloudflare Local Tunnel Setup

This repository contains the configuration files and scripts to seamlessly integrate a local n8n instance using a secure Cloudflare Tunnel for exposure, all managed with Docker Compose.

## Features

- Dockerized Environment: Runs n8n and Cloudflare connector in isolated containers.
- Secure Tunnelling: Exposes the local n8n instance securely via Cloudflare without opening local firewall ports.
- Persistent Data: Uses Docker volumes or bind mounts to ensure your n8n workflows and credentials are never lost.
- Automated Setup: Uses docker compose to bring up the entire environment with a single command.

## Getting Started

### 1. Clone the Repository

First, clone this repository to your local machine using Git:
bash
git clone https://github.com/silenceway/n8n-docker-local.git
cd n8n-docker-local
Usa el código con precaución.

### 2. Prerequisites

Before you start, ensure you have the following:
1. Docker Desktop installed: Ensures docker and docker compose commands are available.
2. (Optional) A Cloudflare Account & Domain: You must own a domain and have it managed by Cloudflare DNS.

### Option A: Persistent Tunnel (Recommended)

This is the most stable method. It uses a fixed URL (e.g., https://n8n.yourdomain.com) which is ideal for persistent webhooks.

1. Cloudflare Setup (Web UI)

- Go to the Cloudflare Zero Trust Dashboard > Networks > Tunnels.
- Create a new tunnel (e.g., n8n-tunnel).
- Copy your TUNNEL_TOKEN shown in the configuration screen.
- In the Public Hostnames tab, configure your domain:
Subdomain: n8n
Domain: yourdomain.com
Service Type: HTTP
URL: http://n8nn:5678 (This is the internal Docker service name)

2. Configure the docker-compose.yml file

Open the docker-compose.yml file in the cloned repository and replace the placeholder values (<...>):
yaml

# ... (file content from the repo) ...
    environment:
      # --- REPLACE THESE VALUES ---
      WEBHOOK_URL: https://n8n.yourdomain.com 
      N8N_PROTOCOL: https
      TZ: America/Bogota # Your Timezone
      # ...
    environment:
      # --- REPLACE WITH YOUR TOKEN FROM STEP 1.3 ---
      TUNNEL_TOKEN: <YOUR_CLOUDFLARE_TUNNEL_TOKEN>
# ...

Usa el código con precaución.

3. Running the Setup

- Ensure the Docker network exists (only required once):
bash
docker network create n8n_network
Usa el código con precaución.

- Start the services using the docker-compose.yml file in your repository folder:
bash
docker compose up -d
Usa el código con precaución.

Your n8n instance is now available at https://n8n.yourdomain.com.

### Option B: Dynamic Tunnel (Temporary URL)

This option uses temporary URLs (*.trycloudflare.com). The repository includes scripts to automate the dynamic URL injection.

Open the docker-compose-dynamic.yml file and review the configuration.
Use the appropriate script for your OS (start_dynamic.sh for Linux/macOS/WSL or Start-n8nDynamic.ps1 for Windows PowerShell) to orchestrate the startup process.
Refer to the comments within those script files for execution instructions.

If powershell shows error in unsigned script you can use:
> Unblock-File -Path .\Start-n8nDynamic.ps1
