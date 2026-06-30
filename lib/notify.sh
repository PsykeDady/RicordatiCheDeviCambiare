# shellcheck shell=bash
#
# notify.sh — Invio delle notifiche desktop ed eventuale suono.
#
# Usa notify-send (libnotify). Quando eseguito da un timer systemd il bus
# DBus della sessione potrebbe non essere noto: lo ricaviamo da
# /run/user/<uid>/bus come fallback.

# rcdc_ensure_dbus — Garantisce che notify-send trovi il bus di sessione.
rcdc_ensure_dbus() {
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        local bus
        bus="/run/user/$(id -u)/bus"
        if [[ -S "$bus" ]]; then
            export DBUS_SESSION_BUS_ADDRESS="unix:path=$bus"
        fi
    fi
}

# rcdc_expand_message <messaggio> <giorni>
#
# Sostituisce il segnaposto %s con il numero di giorni e interpreta le
# eventuali sequenze di escape unicode (\uXXXX) presenti nei messaggi.
rcdc_expand_message() {
    local msg="$1" days="$2"
    # Prima il segnaposto (accettiamo sia %s che %S per tolleranza).
    msg="${msg//%s/$days}"
    msg="${msg//%S/$days}"
    # Poi neutralizziamo eventuali % residui per usare il testo come
    # formato di printf (che interpreterà gli escape \u).
    msg="${msg//%/%%}"
    # shellcheck disable=SC2059
    printf "$msg"
}

# rcdc_play_sound — Riproduce la notifica sonora, se possibile.
rcdc_play_sound() {
    [[ "${PLAY_SOUND,,}" == "true" ]] || return 0
    command -v paplay >/dev/null 2>&1 || return 0

    local file="$SOUND_FILE"
    if [[ -z "$file" ]]; then
        # Suoni di sistema più comuni, in ordine di preferenza.
        local candidates=(
            "${RCDC_SHARE_DIR:-$HOME/.local/share/ricordatichedevicambiare}/clockalarm.mp3"
            /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
            /usr/share/sounds/freedesktop/stereo/bell.oga
            /usr/share/sounds/freedesktop/stereo/complete.oga
        )
        local c
        for c in "${candidates[@]}"; do
            [[ -r "$c" ]] && { file="$c"; break; }
        done
    fi

    [[ -n "$file" && -r "$file" ]] || return 0
    paplay "$file" >/dev/null 2>&1 &
}

# rcdc_actions_supported — Verifica se notify-send espone il supporto alle azioni.
rcdc_actions_supported() {
    notify-send --help 2>&1 | grep -q -- '--action'
}

# rcdc_notify <livello> <giorni>
#
# Invia la notifica desktop corrispondente al livello indicato.
# Espone anche un'azione "Mostra guida" quando il server di notifiche la
# supporta; su Plasma viene gestita preferendo l'apertura in Konsole.
rcdc_notify() {
    local level="$1" days="$2"

    command -v notify-send >/dev/null 2>&1 || {
        echo "rcdc: notify-send non disponibile" >&2
        return 1
    }

    rcdc_ensure_dbus

    local msg_var="LV${level}_MESSAGE"
    local raw="${!msg_var}"
    local body
    body="$(rcdc_expand_message "$raw" "$days")"

    local urgency
    urgency="$(rcdc_urgency_for_level "$level")"

    local title="Ricordati che devi cambiare la password"
    local selected=""

    if rcdc_actions_supported; then
        selected="$(
            notify-send \
                --app-name="Ricordati che devi cambiare" \
                --urgency="$urgency" \
                --icon="${NOTIFICATION_ICON:-dialog-warning}" \
                --expire-time=15000 \
                --action="guide=Mostra guida" \
                "$title" \
                "$body"
        )"
    else
        notify-send \
            --app-name="Ricordati che devi cambiare" \
            --urgency="$urgency" \
            --icon="${NOTIFICATION_ICON:-dialog-warning}" \
            "$title" \
            "$body"
    fi

    if [[ "$selected" == "guide" ]]; then
        rcdc_open_guide >/dev/null 2>&1 || true
    fi

    if (( level >= 5 )); then
        rcdc_play_sound
    fi
}
