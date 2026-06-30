# Ricordati che devi cambiare la password

> **"Ricordati che devi Mor- ah no, Ricordati che devi cambiare la password!!"**

Un piccolo strumento per Linux che controlla quando scadrà la password del tuo
account e ti avvisa con notifiche desktop sempre più insistenti man mano che la
scadenza si avvicina. Funziona interamente in spazio utente, senza privilegi di
amministratore durante il normale utilizzo.

## Come funziona

- Ogni giorno un **timer systemd utente** esegue un controllo.
- La data di scadenza viene letta con `chage -l` sul tuo stesso account (nessun
  `sudo` richiesto).
- Se la password scadrà entro `WARNING_DAYS` giorni (default: **10**), viene
  mostrata una notifica desktop.
- Il periodo di preavviso è suddiviso automaticamente in **5 livelli
  equidistanti**: più la scadenza si avvicina, più il tono diventa insistente.
  Cambiando `WARNING_DAYS` la suddivisione si adatta da sola.
- L'ultimo livello riproduce anche una **notifica sonora**, se il sistema la
  supporta.
- Se la password **non ha scadenza** (`never`), non viene fatto nulla.

Con `WARNING_DAYS=10` i livelli coprono queste fasce di giorni mancanti:

| Giorni mancanti | 10–9 | 8–7 | 6–5 | 4–3 | 2–0 |
|-----------------|:----:|:---:|:---:|:---:|:----------:|
| Livello         |  1   |  2  |  3  |  4  | 5 (+ suono) |

## Requisiti

**Obbligatori**

- systemd
- libnotify (`notify-send`)

**Opzionali**

- `paplay` — per la notifica sonora del livello massimo
- `mdcat` — per visualizzare la guida Markdown formattata

L'assenza delle dipendenze opzionali non impedisce il funzionamento.

## Installazione

```bash
./install.sh
```

L'installer:

- rileva le dipendenze mancanti e, **solo se necessario**, chiede conferma per
  installarle con privilegi di amministratore (prosegue comunque se le
  dipendenze opzionali vengono rifiutate);
- copia lo script in `~/.local/bin` e i moduli in
  `~/.local/lib/ricordatichedevicambiare`;
- installa service e timer in `~/.config/systemd/user`;
- crea `~/.config/ricordatichedevicambiare` e, se assente, un file di
  configurazione di default;
- esegue `systemctl --user daemon-reload` e abilita il timer.

L'installazione è **idempotente**: rieseguirla non genera errori né duplica
file, e non sovrascrive la tua configurazione.

> Se `~/.local/bin` non è nel tuo `PATH`, l'installer te lo segnala.

### Disinstallazione

```bash
./uninstall.sh            # rimuove il software, conserva la configurazione
./uninstall.sh --purge    # rimuove anche configurazione e stato
```

## Utilizzo

```bash
ricordatichedevicambiare            # controlla e notifica (come fa il timer)
ricordatichedevicambiare --check    # identico al precedente
ricordatichedevicambiare --test     # simula tutti e 5 i livelli
ricordatichedevicambiare --test 3   # simula solo il livello 3
ricordatichedevicambiare --guide    # mostra la guida per il cambio password
ricordatichedevicambiare --help     # aiuto completo
ricordatichedevicambiare --version  # versione
```

## Configurazione

File: `~/.config/ricordatichedevicambiare/config.conf`

| Opzione | Descrizione |
|---|---|
| `WARNING_DAYS` | Giorni di preavviso (default: 10). |
| `SHOW_NOTIFICATION_EVERY_DAY` | `true`: notifica ogni giorno. `false`: notifica solo quando il livello di urgenza aumenta. |
| `PLAY_SOUND` | Abilita il suono al livello massimo (richiede `paplay`). |
| `SOUND_FILE` | File audio da riprodurre. Se vuoto, usa un suono di sistema. |
| `GUIDE_FILE` | Guida Markdown mostrata con `--guide`. Se vuoto, usa quella di default. |
| `NOTIFICATION_ICON` | Icona della notifica (default: `dialog-warning`). |
| `LV1_MESSAGE` … `LV5_MESSAGE` | Testo dei 5 livelli. `%s` è sostituito con i giorni mancanti. |

La struttura del file permette di aggiungere facilmente nuove opzioni: basta
definire un default in `lib/config.sh` e leggerlo dove serve.

## Codici di uscita

| Codice | Significato |
|:---:|---|
| `0`  | Esecuzione riuscita (inclusa password senza scadenza). |
| `1`  | Errore generico. |
| `2`  | Dipendenza obbligatoria mancante (es. `notify-send`). |
| `3`  | Impossibile determinare la scadenza della password. |
| `64` | Uso errato della riga di comando. |

## Struttura del progetto

```
bin/ricordatichedevicambiare   Script principale (dispatcher)
lib/config.sh                  Caricamento configurazione e default
lib/levels.sh                  Calcolo dei 5 livelli equidistanti
lib/password.sh                Lettura scadenza via chage
lib/state.sh                   Stato persistente tra le esecuzioni
lib/notify.sh                  Notifiche desktop e suono
lib/guide.sh                   Visualizzazione della guida
lib/help.sh                    Testo di aiuto e versione
config/config.conf             Configurazione di default
share/guide.md                 Guida di default
systemd/*.service, *.timer     Unità systemd utente
install.sh / uninstall.sh      Installazione / rimozione
```
