# shellcheck shell=bash
#
# state.sh — Stato persistente tra le esecuzioni.
#
# Serve a gestire SHOW_NOTIFICATION_EVERY_DAY=false: in quel caso vogliamo
# notificare solo quando il livello di urgenza aumenta rispetto all'ultima
# notifica mostrata nello stesso "ciclo" di scadenza.

RCDC_STATE_DIR="${RCDC_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/ricordatichedevicambiare}"
RCDC_STATE_FILE="${RCDC_STATE_FILE:-$RCDC_STATE_DIR/last.state}"

# rcdc_state_get — Legge l'ultimo livello notificato (0 se assente).
rcdc_state_get() {
    if [[ -r "$RCDC_STATE_FILE" ]]; then
        local v
        v="$(cat "$RCDC_STATE_FILE" 2>/dev/null)"
        [[ "$v" =~ ^[0-9]+$ ]] && { echo "$v"; return; }
    fi
    echo 0
}

# rcdc_state_set <livello> — Memorizza l'ultimo livello notificato.
rcdc_state_set() {
    mkdir -p "$RCDC_STATE_DIR" 2>/dev/null || return 0
    echo "$1" > "$RCDC_STATE_FILE" 2>/dev/null || true
}

# rcdc_state_reset — Azzera lo stato (es. quando la password non scade più).
rcdc_state_reset() {
    rcdc_state_set 0
}

# rcdc_should_notify <livello_corrente>
#
# Decide se mostrare la notifica in base a SHOW_NOTIFICATION_EVERY_DAY.
# Restituisce 0 (sì) oppure 1 (no).
rcdc_should_notify() {
    local level="$1"

    if [[ "${SHOW_NOTIFICATION_EVERY_DAY,,}" == "true" ]]; then
        return 0
    fi

    # Modalità "solo quando aumenta l'urgenza".
    local last
    last="$(rcdc_state_get)"
    if (( level > last )); then
        return 0
    fi
    return 1
}
