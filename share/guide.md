# Come cambiare la password

La tua password sta per scadere. Cambiarla è semplice e richiede meno di un minuto.

## Da terminale

1. Apri un terminale.
2. Esegui:

   ```bash
   passwd
   ```

3. Inserisci la **password attuale** quando richiesto.
4. Inserisci la **nuova password** e confermala.

## Se usi eCryptfs

Se il tuo home o una directory privata usa `ecryptfs`, dopo aver cambiato la
password di login devi aggiornare anche la wrapping passphrase, altrimenti il
mount automatico potrebbe smettere di funzionare.

1. Dopo aver eseguito `passwd`, lancia:

   ```bash
   ecryptfs-rewrap-passphrase ~/.ecryptfs/wrapped-passphrase
   ```

2. Quando richiesto:
   - inserisci la **vecchia password di login** come `Old wrapping passphrase`;
   - inserisci la **nuova password di login** come `New wrapping passphrase`;
   - conferma di nuovo la **nuova password**.

Se usi `ecryptfs-mount-private` o il mount automatico via PAM, questo passaggio
serve a mantenere allineato `~/.ecryptfs/wrapped-passphrase` con la password
appena impostata.

## Consigli per una buona password

- Almeno 12 caratteri.
- Mescola maiuscole, minuscole, numeri e simboli.
- Evita parole comuni, date di nascita e password già usate.
- Valuta l'uso di una passphrase: più parole casuali sono facili da ricordare
  e difficili da indovinare.

## Hai cambiato la password?

Perfetto! Le notifiche smetteranno automaticamente al prossimo controllo,
quando rileveranno la nuova data di scadenza.
