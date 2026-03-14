# infra-kit

VPS bootstrap wizard. Modular, idempotent, Gum-powered.

## Usage

```bash
# From a fresh VPS (as root):
bash <(curl -s https://raw.githubusercontent.com/LuMatRod/infra-kit/main/setup.sh)
```

First run installs Gum + Doppler and exits if auth is needed:

```
▸ Doppler not authenticated.
  Run:  doppler login
  Then: bash setup.sh
```

Second run launches the full wizard.

## Structure

```
setup.sh          # wizard entrypoint
verify.sh         # post-setup sanity checks

core/             # always runs (order matters)
  user.sh         # create user, fetch SSH keys from GitHub
  ssh.sh          # custom port, no root, key-only
  firewall.sh     # UFW + fail2ban (with correct SSH port)
  packages.sh     # base packages, UTC timezone
  swap.sh         # 2GB swapfile, swappiness=10
  upgrades.sh     # unattended security upgrades
  tailscale.sh    # join tailnet, enable Tailscale SSH

modules/          # optional, selected via wizard
  node.sh         # Node.js LTS via NodeSource
  openclaw.sh     # OpenClaw install + systemd unit + workspace
  docker.sh       # Docker CE + compose plugin
  caddy.sh        # Caddy reverse proxy
  doppler.sh      # Doppler CLI

lib/
  ui.sh           # gum helpers, run_module, summary
  util.sh         # install_gum, idempotency markers
```

## Routes

| Route | Core | Modules pre-selected |
|-------|------|----------------------|
| OpenClaw | ✓ all | Node.js, OpenClaw, Doppler |
| App | ✓ all | Docker, Caddy, Doppler |
| General | ✓ all | (choose freely) |

## Secrets (Doppler `infra-kit` project)

| Key | Description |
|-----|-------------|
| `TAILSCALE_AUTH_KEY` | Tailscale auth key (rotate every 90 days) |

OpenClaw runtime secrets live in a separate Doppler project (`openclaw`), injected via `doppler run` in the systemd unit — never touched by this script.

## Idempotency

Every module writes a marker to `/var/lib/infra-kit/<module>.done` on success. Re-running setup skips completed modules unless the marker is removed.

## Adding a new module

1. Create `modules/yourmodule.sh`
2. Add `mark_done "yourmodule"` at the end
3. Add it to the wizard choices in `setup.sh`
4. Add a verify check in `verify.sh` if applicable
