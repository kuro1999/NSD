# Antivirus sandbox (central-node + AV1/AV2/AV3)

## 1. Obiettivo
- 3 runner AV su LAN1
- central-node su LAN3 distribuisce file e raccoglie risultati
- runner ripristinati “puliti” ad ogni scan (snapshot/restore o reset stateless)
- prevenzione esfiltrazione: AV possono parlare solo con central-node

## 2. Architettura
- central-node:
  - invio sample ai runner (scp/ssh o altro metodo documentato)
  - esecuzione orchestrazione (script)
  - raccolta risultati
  - generazione report (markdown/json)

- runner AV (AV1/AV2/AV3):
  - script `scan.sh` uniforme
  - output standard (es. JSON con engine, verdict, signature, timestamp)

## 3. Flusso operativo
1. central-node riceve sample (o lo crea)
2. invio sample a runner
3. ciascun runner scansiona e produce output
4. central-node aggrega in report
5. reset runner (snapshot/restore)

## 4. Standard output (da mantenere uguale su tutti i runner)
Campi minimi:
- sample_hash (sha256)
- engine_name
- engine_version (se disponibile)
- verdict (clean/malicious/suspicious/unknown)
- signature (se presente)
- scan_time_utc

## 5. Evidenze
- Log orchestrazione e output scan in `evidence/`
- Report finale in `evidence/reports/` (creare cartella)