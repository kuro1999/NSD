#!/bin/bash
# test.sh - Invia malware e raccoglie i report

# CONFIGURAZIONE IP
IP_AV1="10.200.1.11" # Metti gli IP corretti della tua rete
IP_AV2="10.200.1.12"
IP_AV3="10.200.1.13"
VIRUS_FILE="virus.exe"

# Pulizia vecchi report locali
rm -f report_av*.txt

echo "=============================================="
echo "   CENTRAL NODE - MALWARE ANALYSIS SYSTEM     "
echo "=============================================="

# 1. Prepara l'ascolto dei report (in background)
echo "[*] Avvio listener per i report in ingresso..."
nc -l -p 9001 > report_av1.txt &
PID1=$!
nc -l -p 9002 > report_av2.txt &
PID2=$!
nc -l -p 9003 > report_av3.txt &
PID3=$!

# Piccola pausa per essere sicuri che nc sia partito
sleep 1

# 2. Invia il Malware
if [ ! -f "$VIRUS_FILE" ]; then
    echo "Errore: $VIRUS_FILE non trovato! Crealo prima."
    exit 1
fi

echo "[*] Invio malware ($VIRUS_FILE) ai nodi..."
nc -w 1 $IP_AV1 9000 < $VIRUS_FILE
echo "    -> Inviato a AV1"
nc -w 1 $IP_AV2 9000 < $VIRUS_FILE
echo "    -> Inviato a AV2"
nc -w 1 $IP_AV3 9000 < $VIRUS_FILE
echo "    -> Inviato a AV3"

echo "[*] Attesa risultati (Timeout 10s)..."

# 3. Attesa attiva dei file (o timeout)
# Aspetta che i processi nc di ascolto terminino (terminano appena ricevono il file)
wait $PID1 $PID2 $PID3 2>/dev/null

echo ""
echo "=============================================="
echo "             RISULTATI ANALISI                "
echo "=============================================="

echo ""
echo ">>> REPORT AV1 (ClamAV):"
cat report_av1.txt

echo ""
echo ">>> REPORT AV2 (YARA):"
cat report_av2.txt

echo ""
echo ">>> REPORT AV3 (AIDE):"
cat report_av3.txt

echo "=============================================="
echo "Analisi completata."
