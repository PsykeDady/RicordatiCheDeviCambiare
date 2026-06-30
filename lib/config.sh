# shellcheck shell=bash
#
# config.sh — Caricamento della configurazione e valori di default.
#
# La configurazione è un semplice file KEY=value (sintassi compatibile con
# bash) in ~/.config/ricordatichedevicambiare/config.conf.
# La struttura permette di aggiungere nuove opzioni in futuro: basta
# aggiungere un default qui sotto e leggerlo dove serve.

RCDC_CONFIG_DIR="${RCDC_CONFIG_DIR:-$HOME/.config/ricordatichedevicambiare}"
RCDC_CONFIG_FILE="${RCDC_CONFIG_FILE:-$RCDC_CONFIG_DIR/config.conf}"
RCDC_SHARE_DIR="${RCDC_SHARE_DIR:-$HOME/.local/share/ricordatichedevicambiare}"

# rcdc_set_defaults — Imposta i valori di default per ogni opzione.
# Le variabili sono usate dagli altri moduli (notify/guide/levels).
# shellcheck disable=SC2034
rcdc_set_defaults() {
    WARNING_DAYS=10

    SHOW_NOTIFICATION_EVERY_DAY=true

    PLAY_SOUND=true
    SOUND_FILE="$RCDC_SHARE_DIR/clockalarm.mp3"

    GUIDE_FILE=

    NOTIFICATION_ICON=dialog-warning

    LV1_MESSAGE="La password scadrà tra %s giorni, mi raccomando di cambiarla in tempo"
    LV2_MESSAGE="La password scadrà tra %s giorni, mi raccomando di cambiarla in tempo"
    LV3_MESSAGE="La password scadrà tra %s giorni, se non la cambi in tempo sarà un casino non potrai accedere"
    LV4_MESSAGE="ATTENZIONE: La password scadrà tra %s giorni. CAMBIALA, FOLLE!!"
    LV5_MESSAGE="URGENZA: LA PASSWORD SCADRÀ TRA %s GIORNI, CAMBIALA IMMEDIATAMENTE O SARÀ UN INFERNO"
}

# rcdc_load_config — Carica i default e poi sovrascrive con il file utente.
rcdc_load_config() {
    rcdc_set_defaults

    if [[ -f "$RCDC_CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$RCDC_CONFIG_FILE"
    fi

    # Normalizzazione: WARNING_DAYS deve essere un intero positivo.
    if ! [[ "$WARNING_DAYS" =~ ^[0-9]+$ ]] || (( WARNING_DAYS <= 0 )); then
        WARNING_DAYS=10
    fi
}
