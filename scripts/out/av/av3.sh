#!/bin/bash
#v3.sh - STRACE Listener Daemon (Sandbox)
CENTRAL_NODE_IP="10.202.3.10"
sleep 20

# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888

# 2. Installa
apt-get update
apt-get install -y strace netcat

# 3. Pulisci
unset http_proxy
unset https_proxy

echo "[AV3] SANDBOX Service avviato in ascolto sulla porta 9000..."

if ! command -v strace &> /dev/null; then
    echo "Errore: strace non trovato!"
    exit 1
fi

while true; do
    rm -f binary report.txt
    nc -l -p 9000 > binary

    if [ -s binary ]; then
        echo "[AV3] File ricevuto. Avvio esecuzione sandbox..."

        chmod +x binary

        echo "--- REPORT AV3 (STRACE DYNAMIC ANALYSIS) ---" > report.txt
        date >> report.txt

        timeout 5s strace -f -e trace=openat,connect,execve,unlink ./binary >> report.txt 2>&1
    else
        echo "[AV3] Errore: File ricevuto vuoto o non valido." > report.txt
    fi

    nc -w 2 $CENTRAL_NODE_IP 9003 < report.txt

    rm -f binary report.txt
    echo "[AV3] Ciclo completato."
done
