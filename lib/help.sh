# shellcheck shell=bash
#
# help.sh — Testo di aiuto e versione.

RCDC_VERSION="1.0.0"

rcdc_version() {
    echo "ricordatichedevicambiare $RCDC_VERSION"
}

rcdc_help() {
    cat <<'EOF'
ricordatichedevicambiare — ti ricorda di cambiare la password prima che scada

UTILIZZO
    ricordatichedevicambiare [OPZIONE]

    Senza argomenti esegue il controllo della scadenza password ed,
    eventualmente, mostra la notifica. È la modalità usata dal timer systemd.

OPZIONI
    (nessuna)        Controlla la scadenza e notifica se necessario.
    --check          Identico all'esecuzione senza argomenti.
    --test [1-5]     Simula le notifiche senza attendere la reale scadenza.
                     Senza numero simula tutti e 5 i livelli in sequenza;
                     con un numero simula solo quel livello. Se il server di
                     notifiche supporta le azioni, compare anche "Mostra guida".
    --guide          Mostra la guida per il cambio password.
    --help, -h       Mostra questo aiuto.
    --version, -V    Mostra la versione.

FILE DI CONFIGURAZIONE
    ~/.config/ricordatichedevicambiare/config.conf

    Opzioni principali:
      WARNING_DAYS                 giorni di preavviso (default: 10).
      SHOW_NOTIFICATION_EVERY_DAY  true = notifica ogni giorno; false = notifica
                                   solo quando il livello di urgenza aumenta.
      PLAY_SOUND / SOUND_FILE      notifica sonora per il livello massimo.
      GUIDE_FILE                   guida Markdown da mostrare con --guide.
      NOTIFICATION_ICON            icona della notifica.
      LV1_MESSAGE..LV5_MESSAGE     testo dei 5 livelli (%s = giorni mancanti).

    Il periodo di preavviso viene diviso automaticamente in 5 livelli
    equidistanti: cambiando WARNING_DAYS l'aggressività si adatta da sola.

MODALITÀ DI TEST
    ricordatichedevicambiare --test       # tutti i livelli
    ricordatichedevicambiare --test 3     # solo il livello 3

CODICI DI USCITA
    0   esecuzione riuscita (inclusa password senza scadenza).
    1   errore generico.
    2   dipendenza obbligatoria mancante (es. notify-send).
    3   impossibile determinare la scadenza della password.
    64  uso errato della riga di comando.
EOF
}
