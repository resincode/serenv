---
name: container-deploy
description: Deploy a source repo from ~/Developments as a rootless podman container on this host, published at <app>.keton.id through the host Caddy. Use when asked to containerize, deploy, serve, publish, or set up a domain for an app on this server.
---

# Container Deploy (podman + Caddy)

Host conventions, already installed on this machine:

- **Source**: `~/Developments/<app>` (git clone)
- **Deployment**: `~/Deployments/<app>/` — holds `deploy.sh`, `<app>.container` (podman quadlet), `<app>.caddyfile`
- **Runtime**: rootless podman as `res`, systemd user units (linger enabled)
- **Public entry**: system Caddy (`/etc/caddy/Caddyfile` imports `/etc/caddy/Caddyfile.d/*.caddyfile`)
- **Domain pattern**: `https://<app>.keton.id`

## Layout

```text
~/Developments/<app>/          # source, from git
~/Deployments/<app>/
├── deploy.sh                  # build | up | down | status | logs | caddy-logs | cert
├── <app>.container            # podman quadlet -> ~/.config/containers/systemd/
└── <app>.caddyfile           # site block -> /etc/caddy/Caddyfile.d/
```

## Runbook: deploy a new app

1. **Clone the source.**
   ```bash
   ~/.omp/agent/skills/gitlab-playcourt/scripts/glab clone <group>/<app> ~/Developments/<app>
   ```
   Requires a `Dockerfile` in the repo. If absent, stop and ask which image/build the app needs.

2. **Scaffold the deployment dir.**
   ```bash
   ~/.omp/agent/skills/container-deploy/scripts/scaffold <app> <container-port> [domain]
   ```
   It allocates the next free loopback port from 18080 upward, copies `deploy.sh` plus the
   quadlet and Caddy site templates, and rewrites the app name, port, and domain
   (`<app>.keton.id` by default). Nothing else needs hand-editing.

3. **Build and publish.**
   ```bash
   cd ~/Deployments/<app>
   ./deploy.sh build      # podman build -t localhost/<app>:latest ~/Developments/<app>
   ./deploy.sh up         # quadlet + caddy site, waits for health, reloads Caddy
   ```

4. **Verify.**
   ```bash
   ./deploy.sh status
   curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:<hostport>/
   curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: <app>.keton.id' http://127.0.0.1/
   ```

## Port convention

Each app gets its own loopback port; nothing is published on `0.0.0.0`.

| App | Host port | Container port |
|---|---|---|
| xdiag | 18080 | 8080 |

Next app: use 18081, then 18082, and so on.

## Why these choices

- **Rootless podman + quadlet**: no daemon, no root, restarts survive reboot via linger.
  Quadlet unit is generated into `/run/user/<uid>/systemd/generator/` — never hand-edit that.
- **Loopback-only publish**: Caddy is the only process listening publicly; the app cannot be
  reached over plain HTTP from the network even if DNS changes.
- **Caddy drop-in dir**: `/etc/caddy/Caddyfile` on this distro already ends with
  `import Caddyfile.d/*.caddyfile`, so per-app site blocks never touch the packaged file.
- **Caddy logs go to the journal**: writing to `/var/log/caddy` fails because the systemd unit
  sets `ProtectSystem=full` (only `/var/lib/caddy` and `/var/log/caddy` are writable and the
  latter is not created by the package). Do not add a `log` block with a file output.
- **Read-only rootfs + dropped caps** for the app container: static SPA needs no writes
  outside `/tmp`.

## Gotchas hit on this host

1. **`$HOME` is `0700`** — the `caddy` user cannot read `~/Deployments`. Site files must be
   `install`ed into `/etc/caddy/Caddyfile.d/` as root; never `import` from `~`.
2. **Caddy log file** — `open /var/log/caddy/*.log: permission denied` under `ProtectSystem=full`.
   Use journal logging (default). Leave out the `log { output file ... }` block.
3. **SELinux is enforcing** — podman handles labels automatically for rootless builds. For bind
   mounts, add `:Z` only if the container is denied, not preemptively.
4. **HEALTHCHECK is ignored** with the OCI image format (`level=warning ... HEALTHCHECK is not
   supported`). Do not rely on it; `deploy.sh up` probes the port directly.
5. **`ip_unprivileged_port_start` is 1024** — containers cannot bind ports below 1024. Publish on
   a high port and let Caddy terminate 80/443.

## DNS requirement (blocking for new domains)

Caddy issues HTTPS certificates automatically, but only if DNS resolves. A new subdomain needs
an `A` record pointing at this host's public IP (`103.193.177.235`), or a CNAME to the apex.
Verify before deploying:

```bash
getent hosts <app>.keton.id || echo "NXDOMAIN - create the DNS record first"
```

If DNS is not ready, `deploy.sh up` still succeeds and the container serves on loopback; Caddy
keeps retrying the ACME order in the background. Check with:

```bash
sudo journalctl -u caddy -n 40 --no-pager -g 'obtain|certificate|challenge'
```

## Operations

| Task | Command |
|---|---|
| Rebuild after a source change | `cd ~/Deployments/<app> && ./deploy.sh build && ./deploy.sh up` |
| Container logs | `./deploy.sh logs 200` |
| Caddy logs | `./deploy.sh caddy-logs 200` |
| Status (unit, container, caddy, DNS) | `./deploy.sh status` |
| Stop and remove the public site | `./deploy.sh down` |
| Inspect the running container | `podman inspect <app>` / `podman exec -it <app> sh` |

## Security rules

- Never store credentials in `~/Deployments` or the image; pass them as env vars at runtime.
- Never publish a port on `0.0.0.0`; use `127.0.0.1:<port>` and let Caddy proxy.
- Never `chmod 0755 $HOME` to work around the Caddy read problem — install the file instead.
