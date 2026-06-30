# shellcheck shell=bash
#
# levels.sh — Calcolo del livello di aggressività delle notifiche.
#
# Il periodo di preavviso (WARNING_DAYS) viene suddiviso in 5 livelli
# equidistanti, senza soglie fisse. Modificando WARNING_DAYS il
# comportamento si adatta automaticamente.

# rcdc_level <giorni_rimanenti> <warning_days>
#
# Restituisce (stdout) il livello di aggressività:
#   0  -> fuori dal periodo di preavviso, nessuna notifica
#   1  -> livello meno aggressivo (inizio periodo di preavviso)
#   5  -> livello più aggressivo (scadenza imminente / superata)
#
# La banda di ogni livello è ampia WARNING_DAYS/5 giorni. Con il default
# WARNING_DAYS=10 ogni livello copre 2 giorni:
#   rem 10..9 -> 1   rem 8..7 -> 2   rem 6..5 -> 3   rem 4..3 -> 4   rem 2..0 -> 5
rcdc_level() {
    local remaining="$1"
    local warning_days="$2"

    # Periodo di preavviso non valido: nessuna notifica.
    if (( warning_days <= 0 )); then
        echo 0
        return
    fi

    # Ancora fuori dal periodo di preavviso.
    if (( remaining > warning_days )); then
        echo 0
        return
    fi

    # Già scaduta o scade oggi: massima aggressività.
    if (( remaining <= 0 )); then
        echo 5
        return
    fi

    # Quanto siamo "dentro" il periodo di preavviso (0 = appena entrati).
    local position=$(( warning_days - remaining ))

    # level = floor(position * 5 / warning_days) + 1, con clamp [1,5].
    local level=$(( position * 5 / warning_days + 1 ))
    (( level < 1 )) && level=1
    (( level > 5 )) && level=5

    echo "$level"
}

# rcdc_days_for_level <livello> <warning_days>
#
# Restituisce un numero di giorni rappresentativo per il livello indicato,
# usato dalla modalità di test per simulare le notifiche.
#   L1 -> WARNING_DAYS    L5 -> WARNING_DAYS/5
rcdc_days_for_level() {
    local level="$1"
    local warning_days="$2"
    local days=$(( warning_days * (6 - level) / 5 ))
    (( days < 0 )) && days=0
    echo "$days"
}

# rcdc_urgency_for_level <livello>
#
# Mappa il livello sull'urgenza di notify-send (low|normal|critical).
rcdc_urgency_for_level() {
    case "$1" in
        1) echo low ;;
        2|3) echo normal ;;
        4|5) echo critical ;;
        *) echo normal ;;
    esac
}
