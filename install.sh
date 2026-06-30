#!/usr/bin/env bash
#
# install.sh — Installa "Ricordati che devi cambiare la password" per l'utente
# corrente, senza privilegi di amministratore (eccetto l'eventuale
# installazione delle dipendenze di sistema).
#
# È idempotente: può essere eseguito più volte senza errori né duplicazioni.

set -euo pipefail

# --- Percorsi -----------------------------------------------------------------
SRC_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

BIN_DIR="$HOME/.local/bin"
LIB_DIR="$HOME/.local/lib/ricordatichedevicambiare"
SHARE_DIR="$HOME/.local/share/ricordatichedevicambiare"
CONFIG_DIR="$HOME/.config/ricordatichedevicambiare"
SYSTEMD_DIR="$HOME/.config/systemd/user"

APP_NAME="ricordatichedevicambiare"

# --- Output -------------------------------------------------------------------
info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }

# --- Rilevamento del gestore di pacchetti -------------------------------------
detect_pkg_manager() {
    if command -v pacman >/dev/null 2>&1; then echo pacman
    elif command -v apt-get >/dev/null 2>&1; then echo apt
    elif command -v dnf >/dev/null 2>&1; then echo dnf
    elif command -v zypper >/dev/null 2>&1; then echo zypper
    else echo unknown
    fi
}

# pkg_name_for <dipendenza> <gestore> — Nome del pacchetto per quel gestore.
pkg_name_for() {
    local dep="$1" mgr="$2"
    case "$dep:$mgr" in
        notify-send:pacman) echo libnotify ;;
        notify-send:apt)    echo libnotify-bin ;;
        notify-send:dnf)    echo libnotify ;;
        notify-send:zypper) echo libnotify-tools ;;

        paplay:pacman) echo libpulse ;;
        paplay:apt)    echo pulseaudio-utils ;;
        paplay:dnf)    echo pulseaudio-utils ;;
        paplay:zypper) echo pulseaudio-utils ;;

        mdcat:pacman) echo mdcat ;;
        mdcat:apt)    echo mdcat ;;
        mdcat:dnf)    echo mdcat ;;
        mdcat:zypper) echo mdcat ;;

        *) echo "" ;;
    esac
}

# install_packages <pkg...> — Installa via gestore con sudo.
install_packages() {
    local mgr; mgr="$(detect_pkg_manager)"
    case "$mgr" in
        pacman) sudo pacman -S --needed "$@" ;;
        apt)    sudo apt-get update && sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
        *)      return 1 ;;
    esac
}

# --- Gestione dipendenze ------------------------------------------------------
# offer_install <descrizione> <obbligatoria(0/1)> <comando> ...
# Verifica i comandi mancanti, propone l'installazione, usa sudo solo qui.
check_and_offer() {
    local label="$1" mandatory="$2"; shift 2
    local cmds=("$@")

    local missing=()
    local c
    for c in "${cmds[@]}"; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done

    if (( ${#missing[@]} == 0 )); then
        ok "$label: presente"
        return 0
    fi

    local mgr; mgr="$(detect_pkg_manager)"
    local pkgs=()
    for c in "${missing[@]}"; do
        local p; p="$(pkg_name_for "$c" "$mgr")"
        [[ -n "$p" ]] && pkgs+=("$p")
    done

    if (( mandatory == 1 )); then
        warn "$label: MANCANTE (dipendenza obbligatoria: ${missing[*]})"
    else
        warn "$label: mancante (dipendenza opzionale: ${missing[*]})"
    fi

    if [[ "$mgr" == "unknown" || ${#pkgs[@]} -eq 0 ]]; then
        warn "Gestore di pacchetti non riconosciuto: installa manualmente: ${missing[*]}"
        if (( mandatory == 1 )); then
            return 1
        fi
        return 0
    fi

    local prompt="Installare ${pkgs[*]} con privilegi di amministratore? [s/N] "
    local reply=""
    read -r -p "$prompt" reply || true
    case "${reply,,}" in
        s|si|sì|y|yes)
            if install_packages "${pkgs[@]}"; then
                ok "Installato: ${pkgs[*]}"
            else
                err "Installazione di ${pkgs[*]} fallita."
                (( mandatory == 1 )) && return 1
            fi
            ;;
        *)
            if (( mandatory == 1 )); then
                err "Dipendenza obbligatoria non installata: impossibile proseguire."
                return 1
            else
                warn "Dipendenza opzionale saltata: proseguo comunque."
            fi
            ;;
    esac
    return 0
}

# --- Installazione file -------------------------------------------------------
install_files() {
    info "Creazione directory…"
    mkdir -p "$BIN_DIR" "$LIB_DIR" "$SHARE_DIR" "$CONFIG_DIR" "$SYSTEMD_DIR"

    info "Copia dello script principale…"
    install -m 0755 "$SRC_DIR/bin/$APP_NAME" "$BIN_DIR/$APP_NAME"

    info "Copia dei moduli…"
    install -m 0644 "$SRC_DIR"/lib/*.sh "$LIB_DIR/"

    info "Copia della guida di default…"
    install -m 0644 "$SRC_DIR/share/guide.md" "$SHARE_DIR/guide.md"

    info "Copia di service e timer…"
    install -m 0644 "$SRC_DIR/systemd/$APP_NAME.service" "$SYSTEMD_DIR/$APP_NAME.service"
    install -m 0644 "$SRC_DIR/systemd/$APP_NAME.timer"   "$SYSTEMD_DIR/$APP_NAME.timer"

    if [[ -f "$CONFIG_DIR/config.conf" ]]; then
        ok "Configurazione già presente: non viene sovrascritta."
    else
        info "Installazione configurazione di default…"
        install -m 0644 "$SRC_DIR/config/config.conf" "$CONFIG_DIR/config.conf"
    fi
}

# --- Attivazione systemd ------------------------------------------------------
enable_timer() {
    if ! command -v systemctl >/dev/null 2>&1; then
        warn "systemctl non disponibile: salto l'attivazione del timer."
        return 0
    fi
    info "Ricarico systemd (user) e abilito il timer…"
    systemctl --user daemon-reload
    systemctl --user enable --now "$APP_NAME.timer"
    ok "Timer abilitato. Prossime esecuzioni:"
    systemctl --user list-timers "$APP_NAME.timer" --no-pager 2>/dev/null || true
}

# --- main ---------------------------------------------------------------------
main() {
    info "Installazione di '$APP_NAME' per l'utente $USER"

    # Dipendenze obbligatorie.
    check_and_offer "systemd"   1 systemctl
    check_and_offer "libnotify" 1 notify-send

    # Dipendenze opzionali.
    check_and_offer "paplay (suono)" 0 paplay
    check_and_offer "mdcat (guida)"  0 mdcat

    install_files
    enable_timer

    echo
    ok "Installazione completata."
    echo "   Prova ora:  $APP_NAME --test"
    echo "   Guida:      $APP_NAME --help"

    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        warn "$BIN_DIR non è nel PATH. Aggiungilo, ad esempio:"
        echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.profile"
    fi
}

main "$@"
