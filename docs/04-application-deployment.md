# 04 - Application Deployment

The application layer utilizes a GitOps pull-model via docker-compose and Dockhand via the Hawser agent.

## 🛳️ Deployment Workflow

We keep `docker-compose.yml` files organized within this repository. 
When code is pushed to Github, the local GitHub Actions runner physically triggers Dockhand's internal REST webhooks. Dockhand then actively pulls the updated configurations down via git and routes the deployment securely to the target nodes via the Hawser APIs.

### Infrastructure vs Services
To avoid monolithic failures and ensure proper resource allocation, the application stacks are split across different virtual machines:
* **Infrastructure Node:** Runs foundational service natively via NixOS OCI mapping (Dockhand), and networking bridges. Other infrastructure services will be in a docker-compose stack orchestrated via Dockhand.
* **Services Node:** Runs higher-level applications via Docker Compose orchestrated via Dockhand (Paperless-ngx, NocoDB, Nextcloud, etc.).

## 🌐 Networking and Ingress

* **No Public Exposure:** No external ports are forwarded to the Homelab from the WAN router. Everything is strictly internal.
* **DNS & DHCP:** A Unifi network manages local domains and IP leases.
* **Tailscale MagicDNS:** Tailscale provides secure remote access into the homelab and seamlessly routes network traffic and resolves device names.
* **SSL Certificates:** TBD. Since services aren't exposed directly, providing internal HTTPS might be achieved by researching and leveraging Tailscale's built-in SSL certificate generation later on.

## 📝 Adding a New Service

1. Create a directory or append to an existing `docker-compose.yml` within the relevant stack folder (e.g. `services-stack`).
2. Commit and push the changes to your `main` branch.
3. The specific path-bound GitHub Actions workflow detects the commit securely.
4. The runner automatically explicitly fires the appropriate Dockhand webhook, deploying the container updates strictly using the authenticated Hawser container natively without any manual human intervention.
