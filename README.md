# GNS3 Lab – Progetto Collaborativo

Questo repository contiene un laboratorio GNS3 strutturato per il lavoro collaborativo tramite Git.

## Obiettivi
- Versionare topologia e configurazioni
- Lavorare in team senza conflitti
- Tenere separate configurazioni, documentazione e script

## Prerequisiti
- GNS3 (stessa versione per tutti)
- Git
- Immagini dei dispositivi installate localmente (non incluse nel repo)

## Struttura del progetto
- docs/ → documentazione
- project/ → file GNS3
- inventory/ → sorgente di verità (opzionale)
- scripts/ → automazione

## Setup rapido
1. Clona il repository
2. Apri GNS3
3. Importa il progetto dalla cartella `project/`
4. Associa le immagini richieste ai nodi

## Regole di collaborazione
- Una persona alla volta modifica la topologia (`lab.gns3`)
- Le configurazioni dei nodi sono indipendenti
- Non caricare immagini o file runtime nel repository
