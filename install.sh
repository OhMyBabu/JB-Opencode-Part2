#!/usr/bin/env bash
# JB-Opencode-Part2 — ONE-SHOT INSTALLER (Hermes Agent-style flow untuk OpenCode)
# Deploy: opencode CLI terbaru + persona GANTENG × FOX + agent config + Fox skills
set -euo pipefail

REPO_URL="https://github.com/OhMyBabu/JB-Opencode-Part2"
FOX_REPO="https://github.com/lhuciverjobs-ui/fox.git"
FOX_DIR="${FOX_SKILLS_DIR:-$HOME/fox}"
OPENCODE_INSTALL_URL="https://opencode.ai/install"
MIN_SKILLS=50

FORCE=0
DRY=0

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --dry-run) DRY=1 ;;
        -h|--help)
            cat <<EOF
Usage: ./install.sh [--force] [--dry-run]

  --force     timpa config OpenCode yang sudah ada (backup dulu)
  --dry-run   tampilkan rencana aksi tanpa mengubah apa pun
  -h --help   bantuan ini

Zero-prompt: gak ada input wajib. Model/auth lewat 'opencode auth login'.
Override lokasi skills: FOX_SKILLS_DIR=/path ./install.sh
EOF
            exit 0 ;;
        *) echo "arg tidak dikenal: $arg (pakai --help)"; exit 1 ;;
    esac
done

info() { printf '\033[1;34m[*]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$1" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
DATA_DIR="${OPENCODE_DATA_DIR:-$HOME/.local/share/opencode}"
BACKUP_DIR="$CONFIG_DIR/backups/jb-opencode-part2-$(date +%Y%m%d%H%M%S)"

# --- sanity template ---
for f in AGENTS.md opencode.jsonc; do
    [[ -f "$SCRIPT_DIR/$f" ]] || { err "template hilang: $f (jalankan dari repo clone)"; exit 1; }
done

v_before="$(opencode --version 2>/dev/null || echo 'belum terpasang')"
info "OpenCode sekarang : $v_before"
info "Config target     : $CONFIG_DIR"
info "Fox skills target : $FOX_DIR/skills"

if [[ "$DRY" == "1" ]]; then
    ok "[DRY-RUN] rencana:"
    echo "  1. install/upgrade opencode -> versi terbaru (installer resmi $OPENCODE_INSTALL_URL)"
    echo "  2. backup config lama (AGENTS.md, opencode.jsonc) -> $BACKUP_DIR (kalo ada)"
    echo "  3. deploy AGENTS.md (persona GANTENG x FOX) -> $CONFIG_DIR/AGENTS.md"
    echo "  4. deploy opencode.jsonc (agent ganteng-fox + skills.paths) -> $CONFIG_DIR/opencode.jsonc"
    echo "  5. clone/update fox skills -> $FOX_DIR (min $MIN_SKILLS SKILL.md)"
    echo "  6. verifikasi: versi, skill count, config parse"
    exit 0
fi

# --- 1. opencode terbaru ---
info "Install/upgrade OpenCode via installer resmi ..."
prev_path="$(command -v opencode || true)"
if ! curl -fsSL "$OPENCODE_INSTALL_URL" | bash; then
    err "installer resmi OpenCode gagal"
    exit 1
fi
for p in "$HOME/.opencode/bin" "$HOME/.local/bin" "/usr/local/bin"; do
    [[ -x "$p/opencode" ]] && PATH="$p:$PATH"
done
hash -r 2>/dev/null || true
v_after="$(opencode --version 2>/dev/null || echo 'GAGAL-CEK')"
if [[ "$v_after" == "GAGAL-CEK" ]]; then
    err "opencode gak ketemu setelah install — cek PATH manual: ls ~/.opencode/bin ~/.local/bin"
    exit 1
fi
ok "OpenCode: $v_before -> $v_after"

# --- 2. backup config lama ---
mkdir -p "$CONFIG_DIR"
if [[ -f "$CONFIG_DIR/AGENTS.md" || -f "$CONFIG_DIR/opencode.jsonc" ]]; then
    if [[ "$FORCE" != "1" ]]; then
        warn "config sudah ada di $CONFIG_DIR — pakai --force untuk timpa (backup otomatis)"
        info "AGENTS.md lama dibiarkan, lanjut step skills ..."
    else
        mkdir -p "$BACKUP_DIR"
        cp -a "$CONFIG_DIR/AGENTS.md" "$BACKUP_DIR/" 2>/dev/null || true
        cp -a "$CONFIG_DIR/opencode.jsonc" "$BACKUP_DIR/" 2>/dev/null || true
        ok "backup lama -> $BACKUP_DIR"
    fi
fi

# --- 3. persona ---
if [[ ! -f "$CONFIG_DIR/AGENTS.md" ]] || [[ "$FORCE" == "1" ]]; then
    cp "$SCRIPT_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"
    ok "AGENTS.md (persona GANTENG x FOX) deployed"
else
    info "AGENTS.md lama dipertahankan (tanpa --force)"
fi

# --- 4. agent config (render placeholder) ---
want_cfg=1
[[ -f "$CONFIG_DIR/opencode.jsonc" && "$FORCE" != "1" ]] && want_cfg=0
if [[ "$want_cfg" == "1" ]]; then
    sed -e "s|__CONFIG_DIR__|$CONFIG_DIR|g" \
        -e "s|__FOX_SKILLS__|$FOX_DIR/skills|g" \
        "$SCRIPT_DIR/opencode.jsonc" > "$CONFIG_DIR/opencode.jsonc"
    ok "opencode.jsonc deployed (agent ganteng-fox + skills.paths)"
else
    info "opencode.jsonc lama dipertahankan (tanpa --force)"
fi

# --- 5. fox skills ---
if [[ -d "$FOX_DIR/.git" ]]; then
    info "Update fox repo (git pull) ..."
    git -C "$FOX_DIR" pull --quiet || warn "git pull fox gagal — pakai copy lama"
elif [[ -d "$FOX_DIR" ]]; then
    warn "$FOX_DIR ada tapi bukan git repo — dilewati"
else
    info "Clone fox skills ..."
    git clone --quiet "$FOX_REPO" "$FOX_DIR" || { err "clone fox gagal ($FOX_REPO)"; exit 1; }
fi
N="$(find "$FOX_DIR/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$N" -lt "$MIN_SKILLS" ]]; then
    err "skill count rendah: $N (min $MIN_SKILLS) — cek $FOX_DIR/skills"
    exit 1
fi
ok "Fox skills: $N SKILL.md di $FOX_DIR/skills"

# --- 6. verifikasi ---
info "Verifikasi config ..."
if command -v python3 >/dev/null 2>&1; then
    python3 - "$CONFIG_DIR/opencode.jsonc" <<'PYEOF'
import json, re, sys
raw = open(sys.argv[1], encoding="utf-8").read()
try:
    cfg = json.loads(raw)
except json.JSONDecodeError:
    raw = re.sub(r"^\s*//.*$", "", raw, flags=re.M)
    raw = re.sub(r",(\s*[}\]])", r"\1", raw)
    cfg = json.loads(raw)
ag = cfg["agent"]["ganteng-fox"]
assert ag["temperature"] == 0.2
assert any("AGENTS.md" in p for p in ag["corePrompt"]), "corePrompt bukan AGENTS.md"
assert any("skills" in p for p in cfg["skills"]["paths"]), "skills.paths salah"
assert "__CONFIG_DIR__" not in json.dumps(cfg), "placeholder CONFIG_DIR tidak tersubstitusi"
assert "__FOX_SKILLS__" not in json.dumps(cfg), "placeholder FOX_SKILLS tidak tersubstitusi"
print("config parse OK + placeholder tersubstitusi")
PYEOF
fi
if ! cmp -s "$SCRIPT_DIR/AGENTS.md" "$CONFIG_DIR/AGENTS.md"; then
    warn "AGENTS.md di config beda dari repo (lokal edit? biarkan kalo disengaja)"
else
    ok "AGENTS.md identik dengan repo"
fi
if [[ -f "$DATA_DIR/opencode.db" ]]; then
    info "Session DB lama terdeteksi: $DATA_DIR/opencode.db (history ikut utuh)"
fi

echo
ok "DONE. OpenCode $v_after + persona + $N skills siap."
echo
echo "  Jalankan:   opencode"
echo "  Auth model: opencode auth login   (kalo provider belum ke-login)"
echo "  Agent:      /agents -> ganteng-fox"
echo "  Re-run aman setelah 'opencode update' (config idempotent, pakai --force utk timpa)"
echo
