---
name: gitlab-playcourt
description: Operate GitLab repositories on https://gitlab.playcourt.id (clone, list projects, inspect files/CI, open MRs, manage branches) using the PAT_GITLABPLAYCOURT personal access token. Use when the user asks to work with Playcourt GitLab, or to clone/deploy a playcourt repo into ~/Developments and serve it from ~/Deployments.
---

# GitLab Playcourt Operations

Server: `https://gitlab.playcourt.id` (GitLab self-managed, API v4).
Auth: personal access token stored as env var `PAT_GITLABPLAYCOURT` in `~/.env`.

## Credential handling (read this first)

- The token lives ONLY in `~/.env`. `~/.zshenv` exports it into every zsh session, so
  `$PAT_GITLABPLAYCOURT` is already set in a normal shell.
- In a non-zsh shell (bash script, cron, container): `set -a; . "$HOME/.env"; set +a`.
- NEVER print the token, echo it, commit it, or write it into a repo, `.git/config`,
  `models.yml`, or any deploy file.
- NEVER put the token in a git remote URL that persists. Use the ephemeral clone form
  below, then reset the remote to the clean URL.
- If a command would surface the token in output, redirect or filter it first.

## Helper script

`scripts/glab` (next to this file) wraps the API and handles auth + URL quoting:

```bash
~/.omp/agent/skills/gitlab-playcourt/scripts/glab <command> [args]
```

Commands:

| Command | Purpose |
|---|---|
| `whoami` | Verify the token and print the authenticated user |
| `projects [search]` | List projects (optionally filtered by substring) |
| `project <path-or-id>` | Show one project (clone URLs, default branch, visibility) |
| `tree <path-or-id> [ref]` | Recursive repo tree |
| `file <path-or-id> <file> [ref]` | Print a raw file |
| `branches <path-or-id>` | List branches |
| `mrs <path-or-id> [state]` | List merge requests (`opened` default) |
| `pipelines <path-or-id>` | Recent pipelines |
| `clone <path-or-id> <dest>` | Clone via PAT without persisting the token |
| `api <METHOD> <endpoint> [json-body]` | Escape hatch: raw API call (`endpoint` without `/api/v4`) |

`<path-or-id>` accepts a numeric id (`33908`) or a URL-encoded path (`resa%2Fxdiag`).

## Standard workflows

### Clone a repo into ~/Developments

```bash
~/.omp/agent/skills/gitlab-playcourt/scripts/glab clone resa/xdiag ~/Developments/xdiag
```

The script clones with the token over HTTPS, then immediately resets `origin` to
`https://gitlab.playcourt.id/<path>.git` so the credential is never stored. Subsequent
`git fetch`/`git push` reuse the credential helper configured below.

### Credential helper (one-time, per user)

So `git push`/`git fetch` work without re-embedding the token, install a store-free
helper that reads the token from the environment at call time:

```bash
~/.omp/agent/skills/gitlab-playcourt/scripts/credential-helper
```

It sets `credential.https://gitlab.playcourt.id.helper` in `~/.gitconfig` to a shell
function reading `$PAT_GITLABPLAYCOURT`; the secret stays in `~/.env` only. Remove it with
`credential-helper --remove`. Requires the variable to be exported by the calling shell
(true for zsh via `~/.zshenv`; otherwise `set -a; . ~/.env; set +a`).

### Deploy a repo as a container on this host

Deployments live in `~/Deployments/<app>`. See the `container-deploy` skill for the full
runbook (podman build, systemd user unit, Caddy reverse proxy, DNS).

## Conventions

- Use API v4 with the `PRIVATE-TOKEN` header, never `?private_token=` (leaks into logs).
- URL-encode project paths (`resa/xdiag` -> `resa%2Fxdiag`); the helper does this.
- Prefer `--depth 1` clones for deploy-only checkouts; full clones for development.
- Report failures with the HTTP status the API returned, not just "failed".
