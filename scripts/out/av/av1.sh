#!/bin/bash
# service_av.sh - ClamAV Listener Daemon
CENTRAL_NODE_IP="10.202.3.10" # Sostituisci con IP vero del Central Node
sleep 20
echo "[AV1] setup"
# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888

# 2. Installa
apt-get update
apt-get install -y clamav netcat

# 3. Pulisci (Hardening locale)
unset http_proxy
unset https_proxy
echo "[AV1] setup completed"

echo "[AV1] ClamAV Service avviato in ascolto sulla porta 9000..."

while true; do
    rm -f binary report.txt
    nc -l -p 9000 > binary
    echo "[AV1] File ricevuto. Avvio scansione..."

    echo "--- REPORT AV1 (ClamAV) ---" > report.txt
    date >> report.txt
    clamscan binary >> report.txt

    echo "[AV1] Invio report..."
    nc -w 2 $CENTRAL_NODE_IP 9001 < report.txt

    rm -f binary report.txt

    echo "[AV1] Ciclo completato. In attesa del prossimo file."
    echo "----------------------------------------------------"
done
