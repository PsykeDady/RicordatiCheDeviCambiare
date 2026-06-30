# shellcheck shell=bash
#
# password.sh — Lettura della scadenza password dell'utente corrente.
#
# Usa `chage -l` che, per il proprio account, funziona senza privilegi di
# amministratore. L'output viene forzato in locale C per un parsing stabile.

# rcdc_password_expiry_epoch
#
# Stampa su stdout:
#   - "never"            se la password non scade
#   - <epoch>            timestamp UNIX della scadenza
# Restituisce:
#   0  in caso di lettura riuscita
#   1  se non è stato possibile determinare la scadenza
rcdc_password_expiry_epoch() {
    local line value epoch

    # Ancorato a inizio riga: evita di intercettare anche la riga
    # "Number of days of warning before password expires".
    line="$(LC_ALL=C chage -l "$USER" 2>/dev/null \
        | grep -iE '^Password expires' | head -n1)" || return 1
    [[ -n "$line" ]] || return 1

    # Estrae il valore dopo i due punti e rimuove gli spazi ai bordi.
    value="${line#*:}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    if [[ -z "$value" ]]; then
        return 1
    fi

    # Nessuna scadenza.
    case "${value,,}" in
        never) echo "never"; return 0 ;;
    esac

    # Converte la data in epoch.
    epoch="$(date -d "$value" +%s 2>/dev/null)" || return 1
    [[ -n "$epoch" ]] || return 1

    echo "$epoch"
}

# rcdc_days_until <epoch>
#
# Stampa il numero (intero) di giorni mancanti alla data indicata.
# Può essere negativo se la data è già passata.
rcdc_days_until() {
    local target="$1"
    local now
    now="$(date +%s)"
    echo $(( (target - now) / 86400 ))
}
