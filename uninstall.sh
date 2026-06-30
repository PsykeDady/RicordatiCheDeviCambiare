#!/usr/bin/env bash
#
# uninstall.sh — Rimuove completamente "Ricordati che devi cambiare la password".
#
# Idempotente: può essere eseguito anche se il software non è installato.
# Per impostazione predefinita conserva la configurazione utente; usa
# --purge per rimuovere anche configurazione e stato.

set -euo pipefail

BIN_DIR="$HOME/.local/bin"
LIB_DIR="$HOME/.local/lib/ricordatichedevicambiare"
SHARE_DIR="$HOME/.local/share/ricordatichedevicambiare"
CONFIG_DIR="$HOME/.config/ricordatichedevicambiare"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ricordatichedevicambiare"
SYSTEMD_DIR="$HOME/.config/systemd/user"

APP_NAME="ricordatichedevicambiare"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }

PURGE=0
[[ "${1:-}" == "--purge" ]] && PURGE=1

# --- Disattivazione timer -----------------------------------------------------
if command -v systemctl >/dev/null 2>&1; then
    info "Disabilito il timer…"
    systemctl --user disable --now "$APP_NAME.timer" 2>/dev/null || true
else
    warn "systemctl non disponibile: salto la disattivazione del timer."
fi

# --- Rimozione file -----------------------------------------------------------
info "Rimuovo i file installati…"
rm -f "$BIN_DIR/$APP_NAME"
rm -f "$SYSTEMD_DIR/$APP_NAME.service"
rm -f "$SYSTEMD_DIR/$APP_NAME.timer"
rm -rf "$LIB_DIR"
rm -rf "$SHARE_DIR"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

# --- Configurazione e stato ---------------------------------------------------
if (( PURGE == 1 )); then
    info "Rimuovo configurazione e stato (--purge)…"
    rm -rf "$CONFIG_DIR"
    rm -rf "$STATE_DIR"
else
    rm -rf "$STATE_DIR"
    if [[ -d "$CONFIG_DIR" ]]; then
        warn "Configurazione conservata in $CONFIG_DIR (usa --purge per rimuoverla)."
    fi
fi

ok "Disinstallazione completata."
