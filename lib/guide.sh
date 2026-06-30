# shellcheck shell=bash
#
# guide.sh — Visualizzazione della guida per il cambio password.

# rcdc_resolve_guide_file — Restituisce il percorso della guida configurata.
#
# Usa GUIDE_FILE se impostato, altrimenti la guida di default installata.
rcdc_resolve_guide_file() {
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

    printf '%s\n' "$file"
}

# rcdc_show_guide_file <file> — Mostra un file Markdown in terminale.
#
# Se mdcat è disponibile la guida viene formattata, altrimenti viene
# mostrata come testo semplice.
rcdc_show_guide_file() {
    local file="$1"

    if command -v mdcat >/dev/null 2>&1; then
        mdcat "$file"
    else
        cat "$file"
    fi
}

# rcdc_show_guide — Mostra la guida Markdown configurata.
rcdc_show_guide() {
    local file
    file="$(rcdc_resolve_guide_file)" || return 1
    rcdc_show_guide_file "$file"
}

# rcdc_open_guide — Apre la guida in una finestra separata, preferendo Plasma.
#
# Su Plasma/KDE privilegia Konsole per mantenere la resa Markdown via mdcat.
# In altri ambienti tenta comunque un terminale grafico; se non disponibile
# ricade su xdg-open del file Markdown.
rcdc_open_guide() {
    local file
    file="$(rcdc_resolve_guide_file)" || return 1

    local runner='if command -v mdcat >/dev/null 2>&1; then mdcat "$1"; else cat "$1"; fi; printf "\nPremi Invio per chiudere... "; read -r _'

    if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* || "${XDG_CURRENT_DESKTOP:-}" == *PLASMA* || -n "${KDE_FULL_SESSION:-}" ]]; then
        if command -v konsole >/dev/null 2>&1; then
            konsole --hold -e bash -lc "$runner" bash "$file" >/dev/null 2>&1 &
            return 0
        fi
    fi

    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- bash -lc "$runner" bash "$file" >/dev/null 2>&1 &
        return 0
    fi

    if command -v x-terminal-emulator >/dev/null 2>&1; then
        x-terminal-emulator -e bash -lc "$runner" bash "$file" >/dev/null 2>&1 &
        return 0
    fi

    if command -v kitty >/dev/null 2>&1; then
        kitty bash -lc "$runner" bash "$file" >/dev/null 2>&1 &
        return 0
    fi

    if command -v xterm >/dev/null 2>&1; then
        xterm -hold -e bash -lc "$runner" bash "$file" >/dev/null 2>&1 &
        return 0
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$file" >/dev/null 2>&1 &
        return 0
    fi

    echo "rcdc: impossibile aprire la guida in modo interattivo" >&2
    return 1
}
