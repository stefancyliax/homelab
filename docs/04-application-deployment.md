# 04 - Application Deployment

The application layer utilizes a GitOps pull-model via docker-compose and Komodo.

## 🛳️ Deployment Workflow

We keep `docker-compose.yml` files organized within this repository. 
Komodo monitors the repository, pulls the configurations down, and updates the deployments using native Docker APIs.

### Infrastructure vs Services
To avoid monolithic failures and ensure proper resource allocation, the application stacks are split across different virtual machines:
* **Infrastructure Stack:** Runs foundational services like Komodo itself, and other core network or deployment bridges.
* **Services Stack:** Runs higher-level applications like Paperless-ngx, NocoDB, Nextcloud, etc.

## 🌐 Networking and Ingress

* **No Public Exposure:** No external ports are forwarded to the Homelab from the WAN router. Everything is strictly internal.
* **DNS & DHCP:** A Unifi network manages local domains and IP leases.
* **Tailscale MagicDNS:** Tailscale provides secure remote access into the homelab and seamlessly routes network traffic and resolves device names.
* **SSL Certificates:** TBD. Since services aren't exposed directly, providing internal HTTPS might be achieved by researching and leveraging Tailscale's built-in SSL certificate generation later on.

## 📝 Adding a New Service

1. Create a directory or append to an existing `docker-compose.yml` within the relevant stack folder.
2. Commit and push the changes to GitHub.
3. Komodo automatically detects the commit, pulls any necessary Docker images, and deploys/updates the container workloads without manual intervention.
