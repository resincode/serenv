#!/usr/bin/env bash
# deploy.sh — build, install, and publish one app from ~/Developments as a
# rootless podman container behind the host Caddy.
#
#   ./deploy.sh build        # podman build from ~/Developments/<app> -> localhost/<app>:latest
#   ./deploy.sh up           # install quadlet + caddy drop-in, start both
#   ./deploy.sh down         # stop container, remove caddy drop-in
#   ./deploy.sh status       # unit, container, and caddy state
#   ./deploy.sh logs [n]     # container journal
#   ./deploy.sh caddy-logs [n]
#   ./deploy.sh cert         # force Caddy to (re)issue the TLS certificate
#
# Layout convention: ~/Deployments/<app>/ holds this script plus <app>.container
# (podman quadlet) and <app>.caddyfile (Caddy site). Source: ~/Developments/<app>.
#
# Caddy uses the distro drop-in dir /etc/caddy/Caddyfile.d/*.caddyfile, already
# imported by /etc/caddy/Caddyfile — no edits to the packaged file are needed.
set -euo pipefail

APP="$(basename "$(cd "$(dirname "$0")" && pwd)")"
DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$HOME/Developments/$APP"
IMAGE="localhost/$APP:latest"
QUADLET="$DEPLOY_DIR/$APP.container"
CADDY_SRC="$DEPLOY_DIR/$APP.caddyfile"
CADDY_DROPIN="/etc/caddy/Caddyfile.d/$APP.caddyfile"
QUADLET_DIR="$HOME/.config/containers/systemd"

say()  { printf '\033[1;32m[deploy:%s]\033[0m %s\n' "$APP" "$*"; }
die()  { printf '\033[1;31m[deploy:%s]\033[0m %s\n' "$APP" "$*" >&2; exit 1; }

domain()     { sed -n 's/^\([a-z0-9][a-z0-9.-]*\) {$/\1/p' "$CADDY_SRC" | head -1; }
upstream()   { grep -oE '^PublishPort=127\.0\.0\.1:[0-9]+' "$QUADLET" | sed 's/.*://' | head -1; }

cmd_build() {
    [ -f "$SRC_DIR/Dockerfile" ] || die "no Dockerfile in $SRC_DIR"
    say "building $IMAGE from $SRC_DIR"
    podman build -t "$IMAGE" "$SRC_DIR"
    say "built ${IMAGE} ($(podman image inspect --format '{{.Id}}' "$IMAGE" | cut -c1-19))"
}

cmd_up() {
    local dom up; dom="$(domain)"; up="$(upstream)"
    [ -n "$dom" ] || die "cannot read domain from $CADDY_SRC"
    [ -n "$up" ]  || die "cannot read PublishPort from $QUADLET"

    say "installing quadlet -> $QUADLET_DIR/$APP.container"
    mkdir -p "$QUADLET_DIR"
    install -m 0644 "$QUADLET" "$QUADLET_DIR/$APP.container"

    say "reloading systemd and starting $APP.service"
    systemctl --user daemon-reload
    systemctl --user restart "$APP.service"

    say "waiting for container on 127.0.0.1:$up"
    local i
    for i in $(seq 1 30); do
        curl -fsS -o /dev/null --max-time 2 "http://127.0.0.1:$up/" && break
        [ "$i" -eq 30 ] && die "container not answering on 127.0.0.1:$up after 60s"
        sleep 2
    done
    say "container healthy on 127.0.0.1:$up"

    say "installing caddy site -> $CADDY_DROPIN"
    sudo -n install -D -m 0644 -o root -g root "$CADDY_SRC" "$CADDY_DROPIN"
    sudo -n caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1 \
        || die "caddy config invalid"
    sudo -n systemctl enable --now caddy >/dev/null 2>&1 || true
    sudo -n systemctl reload-or-restart caddy
    say "published: https://$dom"
}

cmd_down() {
    systemctl --user stop "$APP.service" 2>/dev/null || true
    rm -f "$QUADLET_DIR/$APP.container"
    systemctl --user daemon-reload
    if [ -f "$CADDY_DROPIN" ]; then
        sudo -n rm -f "$CADDY_DROPIN"
        sudo -n caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1 && \
            sudo -n systemctl reload-or-restart caddy >/dev/null 2>&1
    fi
    say "stopped $APP and removed the caddy site"
}

cmd_status() {
    printf 'app      : %s\nsource   : %s\nimage    : %s\ndomain   : %s\nupstream : 127.0.0.1:%s\n' \
        "$APP" "$SRC_DIR" "$IMAGE" "$(domain)" "$(upstream)"
    printf -- '--- unit     : %s\n' "$(systemctl --user is-active "$APP.service" 2>/dev/null || true)"
    printf -- '--- container: %s\n' "$(podman ps --filter "name=^${APP}$" --format '{{.Status}} {{.Ports}}' || true)"
    printf -- '--- caddy    : %s\n' "$(sudo -n systemctl is-active caddy 2>/dev/null || true)"
    printf -- '--- dns      : %s\n' "$(getent ahostsv4 "$(domain)" | awk 'NR==1{print $1}')"
    [ -n "$(getent ahostsv4 "$(domain)" | awk 'NR==1{print $1}')" ] || printf -- '    (NXDOMAIN — create the A record, Caddy retries on its own)\n'
}

cmd_cert() { sudo -n journalctl -u caddy -n 40 --no-pager -g 'certificate|acme|tls' || true; }
cmd_logs()       { journalctl --user -u "$APP.service" -n "${1:-80}" --no-pager; }
cmd_caddy_logs() { sudo -n journalctl -u caddy -n "${1:-80}" --no-pager; }

main() {
    local cmd="${1:-}"; shift || true
    case "$cmd" in
        build)      cmd_build ;;
        up)         cmd_up ;;
        down)       cmd_down ;;
        status)     cmd_status ;;
        logs)       cmd_logs "$@" ;;
        caddy-logs) cmd_caddy_logs "$@" ;;
        cert)       cmd_cert ;;
        *)          sed -n '2,18p' "$0" | sed -e 's/^# \{0,1\}//' ;;
    esac
}

main "$@"
