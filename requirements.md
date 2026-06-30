## Requisiti funzionali

* Controllare periodicamente la data di scadenza della password dell'utente corrente.
* Se la password scadrà entro un numero configurabile di giorni (default: 10), mostrare una notifica desktop.
* Il livello di aggressività delle notifiche dovrà essere calcolato automaticamente suddividendo il periodo di preavviso in **5 livelli equidistanti**, senza utilizzare soglie fisse. In questo modo modificando `WARNING_DAYS` il comportamento si adatterà automaticamente.
* L'ultimo livello di aggressività dovrà prevedere anche una notifica sonora, se supportata dal sistema.
* Se la password non ha una scadenza ("never"), non fare nulla.
* Deve essere possibile mostrare una guida personalizzata per il cambio password.
* Il controllo deve essere eseguito automaticamente ogni giorno tramite un **systemd user timer**.
* Il timer deve essere persistente (`Persistent=true`) in modo da eseguire il controllo anche dopo un periodo di spegnimento del PC.
* Non devono essere richiesti privilegi di amministratore durante il normale utilizzo del software.
* Deve essere disponibile il comando `--help`, che descriva tutte le opzioni disponibili.
* Deve essere disponibile il comando `--test`, che permetta di simulare le notifiche senza attendere la reale scadenza della password.

---

## Installazione

Il repository deve poter essere installato semplicemente con:

```bash
./install.sh
```

L'installazione non deve richiedere privilegi amministrativi, **ad eccezione dell'eventuale installazione delle dipendenze di sistema**.

Se vengono rilevate dipendenze mancanti, l'installer dovrà:

* rilevarle automaticamente;
* chiedere all'utente se desidera installarle;
* richiedere privilegi amministrativi solo per questa operazione;
* continuare comunque l'installazione se le dipendenze opzionali non vengono installate.

L'installer deve inoltre:

* copiare lo script principale in `~/.local/bin`;
* copiare service e timer in `~/.config/systemd/user`;
* creare una directory di configurazione in `~/.config/ricordatichedevicambiare`;
* installare un file di configurazione di default se assente;
* eseguire automaticamente:

```bash
systemctl --user daemon-reload
systemctl --user enable --now ricordatichedevicambiare.timer
```

L'installazione deve essere **idempotente**: eseguire `install.sh` più volte non deve generare errori né duplicare file o configurazioni.

Deve inoltre essere presente uno script:

```bash
./uninstall.sh
```

che rimuova completamente il software.

### Dipendenze obbligatorie

* systemd
* libnotify

### Dipendenze opzionali

* `paplay` (riproduzione della notifica sonora)
* `mdcat` (visualizzazione della guida Markdown)

L'assenza delle dipendenze opzionali non deve impedire il funzionamento del software.

---

## Configurazione

La configurazione deve essere salvata in:

```text
~/.config/ricordatichedevicambiare/config.conf
```

Ad esempio:

```ini
WARNING_DAYS=10

SHOW_NOTIFICATION_EVERY_DAY=true

PLAY_SOUND=true
SOUND_FILE=

GUIDE_FILE=

NOTIFICATION_ICON=dialog-warning
LV1_MESSAGE="La password scadr\u00e0 tra %s giorni, mi raccomando di cambiarla in tempo"
LV2_MESSAGE="La password scadr\u00e0 tra %s giorni, mi raccomando di cambiarla in tempo"
LV3_MESSAGE="La password scadr\u00e0 tra %s giorni, se non la cambi in tempo sar\u00e0 un casino non potrai accedere"
LV4_MESSAGE="ATTENZIONE: La password scadr\u00e0 tra %s giorni. CAMBIALA, FOLLE!!"
LV5_MESSAGE="URGENZA: LA PASSWORD SCADR\u00c0 TRA %S GIORNI, CAMBIALA IMMEDIATAMENTE O SAR\u00c0 UN INFERNO"
```

`GUIDE_FILE` dovrà puntare ad un file Markdown contenente la guida che verrà mostrata all'utente quando richiesto.

La struttura del file di configurazione deve permettere facilmente di aggiungere nuove opzioni in futuro.

---

## Notifiche

Utilizzare le notifiche desktop standard di Linux (preferibilmente `notify-send`).

Le notifiche dovranno differenziarsi automaticamente in base al livello di aggressività calcolato.

L'ultimo livello dovrà riprodurre anche una notifica sonora, se disponibile.

Valutare inoltre la possibilità futura di aggiungere pulsanti alle notifiche, ad esempio:

* Mostra guida
* Ricordamelo domani

Queste funzionalità non devono essere implementate in questa prima versione, ma l'architettura dovrà permetterne una facile aggiunta.

---

## Test

Il software dovrà supportare una modalità di test che permetta di verificare il comportamento senza attendere la reale scadenza della password.

Ad esempio:

```bash
ricordatichedevicambiare --test
```

che simula tutti i livelli di notifica.

Facoltativamente:

```bash
ricordatichedevicambiare --test 1
ricordatichedevicambiare --test 2
...
ricordatichedevicambiare --test 5
```

per simulare un livello specifico.

---

## Help

Il software dovrà implementare:

```bash
ricordatichedevicambiare --help
```

che descriva:

* utilizzo;
* opzioni disponibili;
* file di configurazione;
* modalità di test;
* eventuali codici di uscita.

---

## Architettura

Il codice dovrà essere organizzato in più funzioni e, ove opportuno, in più file Bash, evitando uno script monolitico.

L'obiettivo è mantenere il progetto facilmente leggibile, manutenibile ed estendibile.

---

## README

Il README **non dovrà essere scritto all'inizio dello sviluppo**.

Dovrà essere generato esclusivamente al termine del progetto, quando tutte le funzionalità saranno implementate e validate.

Il README dovrà descrivere esclusivamente funzionalità realmente presenti nel software, evitando riferimenti a funzionalità future o non ancora implementate.

L'introduzione dovrà iniziare con la frase:

> **"Ricordati che devi Mor- ah no, Ricordati che devi cambiare la password!!"**
