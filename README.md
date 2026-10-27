# Roomy

**Cleans up after your AI agents.** Roomy finds regenerable developer and agent artifacts — `node_modules`, virtualenvs, build caches, model stores, editor caches, agent scratch directories, stale CLI builds — and removes them safely. Nothing is deleted without a plan, every removal is recorded, and anything that cannot be regenerated is marked *Irreversible* and never bulk-selected.

Roomy is one core with three surfaces:

| Surface | For | Platform |
|---|---|---|
| **Roomy.app** | A developer reviewing and deleting with a UI | macOS 13+ |
| **`roomy` CLI** | Humans at a terminal, and agents (Claude Code, Codex, Cursor, OpenClaw…) that call it with `--json` | macOS, Linux |
| **Roomy Fleet** (`roomy fleet …`) | Unattended cleanup across many agent hosts: policy files, quarantine with retention, tamper-evident audit log, Prometheus metrics, licensing | macOS, Linux |
| **Roomy Hub** (`roomy hub …`) | The central view: every host reports in, one dashboard with inventory, fleet totals, disk pressure and what each policy may touch; managed policies pushed from one place; fleet-wide Prometheus metrics | Linux, macOS (same binary) |

Site: <https://getroomy.dev> · Docs: [`docs/`](docs/) · Release notes: [`CHANGELOG.md`](CHANGELOG.md)

## Why

Agents are now the heaviest producers of disk waste on developer machines and servers, and most of it is the agents' own storage: Cursor's state database and stale agent builds, Claude desktop's VM bundle, Codex crash dumps and log databases, Hugging Face and Ollama model stores, OpenClaw build captures, un-emptied Trash on headless hosts. Every vendor fixes only its own bug, eventually. Roomy covers all of them from one rule catalog and knows which ones are safe to remove.

## Quick start

**Mac app** — download from <https://getroomy.dev>, scan, review, delete.

**CLI**

```sh
# macOS
brew install tdermendjiev/roomy/roomy
# Linux (Debian/Ubuntu); .rpm and .apk on the releases page
sudo dpkg -i roomy_1.3.0_amd64.deb

roomy doctor                           # environment check
roomy scan                             # what could be reclaimed (never deletes)
roomy scan --json                      # same, as data — for agents and scripts
roomy scan --plan plan.json            # write a plan: safe tier only, by default
roomy clean --plan plan.json           # remove exactly what the plan lists
```

**Fleet** (one agent host)

```sh
sudo roomy fleet policy init --profile agent-host --output /etc/roomy/policy.json
roomy fleet policy check               # scan + show what the policy would remove, dispose of nothing
sudo systemctl enable --now roomy-fleet@agent.timer    # every 6h as user "agent"
curl -s localhost:9477/metrics         # with roomy-fleet-serve@agent.service
```

**Hub** (one place for all hosts)

```sh
roomy hub serve --listen 0.0.0.0:9478 --data-dir /var/lib/roomy-hub --agent-token "$(roomy hub token)" --admin-token "$(roomy hub token)"
roomy fleet policy init --profile agent-host --hub http://hub.internal:9478 --tag role=agent --output /etc/roomy/policy.json   # on each host
roomy hub status --url http://hub.internal:9478 --token …   # or open http://hub.internal:9478/ in a browser
roomy hub demo && roomy hub serve --data-dir ~/.roomy/hub-demo   # a synthetic fleet to look at first
```

## Safety model

Three tiers, one vocabulary everywhere (app badges, CLI refusals, fleet policies):

- **Safe** — fully regenerable: `node_modules`, pip/uv/npm caches, model stores, Electron caches, stale CLI builds.
- **Review** (`caution`) — regenerable at a cost, or mixed with user data: Cursor's database backup, conda envs, Docker build cache.
- **Irreversible** (`warning`) — not regenerable: agent session transcripts, Cursor chat database, Xcode archives, Docker volumes. Never bulk-selected, never removed by a policy, refused by `roomy clean` unless `--allow-irreversible`.

Disposal is **Trash** on macOS, **quarantine** (a Roomy-managed holding area with a retention period) on Linux, or permanent delete when asked. `roomy clean` only ever removes paths that appear in a plan file, so a caller never passes raw paths.

## Repository layout

```
Roomy/                 SwiftUI macOS app (front-end only)
Roomy.xcodeproj        depends on the local package below
RoomyCore/             Swift package: core library, fleet library, CLI, tests (published as github.com/tdermendjiev/Roomy)
  Sources/RoomyCore    Foundation-only scanner, rule catalog (JSON), probes, disposal, reports
  Sources/RoomyFleet   policy, evaluator, audit log, metrics, metrics server, license, runner, hub (server, store, client, dashboard.html)
  Sources/roomy        the CLI
packaging/             systemd units, nfpm spec, Dockerfile, Homebrew formula, release scripts, example policy, oss/ (public README + LICENSE)
tools/licensetool/     issuer-side license tool (private, not exported)
docs/                  documentation (see below)
skills/roomy/          Claude Code skill teaching agents how to call roomy
landing/               getroomy.dev
```

## Documentation

- [Architecture](docs/architecture.md) — one core, two front-ends, platform seams
- [CLI reference](docs/cli.md) — commands, flags, exit codes, JSON schemas
- [For AI agents](docs/agents.md) — how an agent should call Roomy, with the plan-file flow
- [Rule catalog](docs/rules.md) — the data format, tiers, adding rules without a release
- [Fleet](docs/fleet.md) — unattended runs, systemd, Prometheus, audit log
- [Hub](docs/hub.md) — central inventory, dashboard, managed policies, API, fleet metrics
- [Policy reference](docs/policy.md) — every field of a policy file
- [Linux notes](docs/linux.md) — trash vs quarantine, service users, containers
- [Packaging and releases](docs/packaging.md) — static builds, .deb/.rpm/.apk, Docker, Homebrew, signing, SBOM
- [Licensing](docs/licensing.md) — community vs fleet edition, offline tokens, issuing keys

## Building

```sh
# Package (macOS or Linux, Swift 5.9+ toolchain; Swift 6.x recommended)
cd RoomyCore && swift build && swift test
.build/debug/roomy scan --no-system ~/workspace

# Mac app
xcodebuild -project Roomy.xcodeproj -scheme Roomy -configuration Debug build

# Release artifacts
packaging/scripts/build-macos.sh        # universal CLI
packaging/scripts/build-linux.sh        # static Linux CLI
packaging/scripts/release.sh 1.3.0      # everything + SBOM + checksums
```

## Roadmap

What stands between the current tree and a product people can install and pay for. Items are removed as they ship.

- [ ] **Publish.** The public repo [tdermendjiev/Roomy](https://github.com/tdermendjiev/Roomy) carries the open-source subset (`main` synced 2026-10-27 with `packaging/scripts/export-os.sh`). Still to do: create the tap `tdermendjiev/homebrew-roomy`, add `HOMEBREW_TAP_TOKEN` to the public repo, then `export-os.sh ../Roomy v1.3.0` and push the tag. The workflow there builds the Linux packages, the container image and the macOS CLI and updates the tap ([docs/packaging.md](docs/packaging.md)).
- [x] **Replace placeholders.** Done: `tdermendjiev/Roomy`, `ghcr.io/tdermendjiev/roomy`, `brew install tdermendjiev/roomy/roomy`, hello@getroomy.dev.
- [ ] **Sign the macOS CLI.** Developer ID signature and notarization for the universal `roomy` binary; the app's 1.3.0 archive and notarization pass.
- [ ] **Sell licenses.** Pricing page, checkout, license delivery and renewal for the Fleet edition. Today a token is minted by hand with `roomy-licensetool`.
- [x] **Central fleet view.** Done in 1.3.0: `roomy hub` with inventory, dashboard, managed policies and fleet-wide metrics ([docs/hub.md](docs/hub.md)). Still to come: alert routing from the hub itself and a hosted option.
- [ ] **Rule coverage from real fleets.** The catalog reflects two machines and public issue trackers; expect a round of rule fixes from early users.
- [ ] **CLI self-update and crash reporting.** Today the only update path is reinstalling the package, and failures surface only as filed issues.
- [ ] **Smaller Linux binary.** The static build is about 63 MB because Foundation links ICU. Linux disposal defaults to quarantine, not the desktop Trash; document both more prominently.

## License

The Mac app and CLI are free to use (see [EULA.md](EULA.md) and [LICENSE](LICENSE)). Roomy Fleet features run in community mode without a license and are unlocked for commercial fleets with a license token; see [docs/licensing.md](docs/licensing.md).
