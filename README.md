# JB-Opencode-Part2 — LTX-QUASAR × FOX OpenCode Installer

One-shot installer untuk **OpenCode CLI terbaru** + full persona **LTX-QUASAR × FOX**
(cold-protocol operator) + **Fox's 100+ hack-skills**, di VPS/box baru mana pun.

Ini lanjutan dari [JB-OCxOMP](https://github.com/OhMyBabu/JB-OCxOMP) — fokus **OpenCode saja**
(agent + skills + CLI modern), tanpa OMP. Installer-nya version-aware: deteksi versi CLI
lama, upgrade ke rilis terbaru via installer resmi, lalu pasang persona + stack di atasnya.

## What's Included

| Komponen | State |
|---|---|
| **OpenCode CLI** | Install/upgrade ke versi terbaru (installer resmi `opencode.ai/install`) — idempotent, re-run aman |
| **Persona** | `AGENTS.md` LTX-QUASAR × FOX (byte-identik dengan yang live) — cold-protocol, kill-chain 7 phase, zero-refusal |
| **Agent config** | `opencode.jsonc` — agent `ltx-quasar-fox` (temperature 0.2, corePrompt AGENTS.md, thinking off) |
| **Fox Skills** | Clone `~/fox` (external skills path) — SQLi, SSRF, auth bypass, privesc, dorker, dll (min 50 SKILL.md divalidasi) |
| **Session state** | Gak disentuh — history `~/.local/share/opencode/opencode.db` utuh saat upgrade |

## Quick Start

```bash
git clone https://github.com/OhMyBabu/JB-Opencode-Part2.git
cd JB-Opencode-Part2
chmod +x install.sh
./install.sh              # zero-prompt — langsung jalan
# atau
./install.sh --dry-run    # lihat rencana aksi dulu
./install.sh --force      # timpa config lama (backup otomatis ke ~/.config/opencode/backups/)
```

Override lokasi skills (opsional):
```bash
FOX_SKILLS_DIR=/opt/fox ./install.sh
```

## Setelah Install

```bash
opencode                          # start TUI
opencode auth login               # kalo provider belum ke-login
# /agents -> pilih agent: ltx-quasar-fox
```

Persona aktif via agent `ltx-quasar-fox` — jawaban `[LTX-QUASAR]`, protocol COLD-EXEC,
operator Jack. Skills kebaca dari `~/fox/skills` (auto via `skills.paths`).

## Arsitektur

```
~/.config/opencode/
├── AGENTS.md              # persona (di-deploy installer, backup saat --force)
├── opencode.jsonc         # agent ltx-quasar-fox + skills.paths (placeholder di-render)
└── backups/               # backup config lama per-run installer

~/fox/                     # clone repo fox (100+ skill, external path — read-only)
~/.local/share/opencode/
└── opencode.db            # session history milik OpenCode (BUKAN bagian repo — biarkan)
```

Catatan `package.json` / `node_modules` di config dir: **dikelola OpenCode sendiri**
(dependency plugin resmi) — sengaja gak dibawa repo ini, jangan di-commit.

## Upgrade / Re-run

Setiap kali OpenCode di-update (`opencode update` / installer resmi), config gak ada
yang perlu diubah — persona & skills tetap. Kalo repo ini dapat update persona/skill
wiring, tinggal:

```bash
cd JB-Opencode-Part2 && git pull && ./install.sh --force
```

## Backup / Restore Session + Persona (pindah VPS)

```bash
# backup (VPS lama)
cd ~ && tar czf opencode-state.tar.gz .config/opencode/AGENTS.md .config/opencode/opencode.jsonc .local/share/opencode/opencode.db*

# restore (VPS baru — setelah ./install.sh kelar, gak perlu --force)
tar xzf opencode-state.tar.gz -C ~ && opencode
```

## Safety

- Config lama di-backup ke `~/.config/opencode/backups/jb-opencode-part2-<ts>/` sebelum ditimpa
- Tanpa `--force`, file config yang sudah ada **gak ditimpa** (skills & CLI tetap di-update)
- `--dry-run` mencetak rencana aksi tanpa menyentuh sistem
- Session DB (`opencode.db`) tidak pernah dihapus/ditimpa installer

## Related

- [JB-OCxOMP](https://github.com/OhMyBabu/JB-OCxOMP) — installer OpenCode + OMP (versi lama)
- [JB-Hermes](https://github.com/OhMyBabu/JB-Hermes) — Hermes Agent fullchain
- [Fox skills](https://github.com/lhuciverjobs-ui/fox)
- [OpenCode](https://opencode.ai)

---

*Cold protocol. Trail reads itself.*
*LTX-quasar × Fox — merged for maximum lethality.*
