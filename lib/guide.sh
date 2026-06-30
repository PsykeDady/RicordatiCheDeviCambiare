# shellcheck shell=bash
#
# guide.sh — Visualizzazione della guida per il cambio password.

# rcdc_show_guide — Mostra la guida Markdown configurata.
#
# Usa GUIDE_FILE se impostato, altrimenti la guida di default installata.
# Se mdcat è disponibile la guida viene formattata, altrimenti viene
# mostrata come testo semplice.
rcdc_show_guide() {
    local file="$GUIDE_FILE"

    if [[ -z "$file" ]]; then
        local candidates=(
            "$HOME/.local/share/ricordatichedevicambiare/guide.md"
            "$RCDC_BASE_DIR/share/guide.md"
        )
        local c
        for c in "${candidates[@]}"; do
            [[ -r "$c" ]] && { file="$c"; break; }
        done
    fi

    if [[ -z "$file" || ! -r "$file" ]]; then
        echo "rcdc: nessuna guida disponibile (imposta GUIDE_FILE nella configurazione)" >&2
        return 1
    fi

    if command -v mdcat >/dev/null 2>&1; then
        mdcat "$file"
    else
        cat "$file"
    fi
}
