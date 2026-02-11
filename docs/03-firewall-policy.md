
---

# Firewall policy 

## Nodi firewall/gateway

* **GW200**

  * verso R201: **2.0.200.2/30** (GW: **2.0.200.1**) 
  * DMZ: **2.80.200.1/24** 

* **eFW**

  * outside/DMZ: **2.80.200.2/24**
  * LAN1: **10.200.1.1/24** 

* **iFW**

  * LAN1: **10.200.1.2/24**
  * LAN2: **10.200.2.1/24** 

---

## Policy richiesta

1. **LAN-client (10.200.2.10) → esterno consentito solo stateful ed inizializzato verso l'esterno**
2. **AV (10.200.1.11-13) ↔ solo central-node (10.202.3.10) via VPN enterprise**
3. **Inbound da esterno consentito solo:**

   * DNS (TCP/UDP 53) verso **2.80.200.3**
   * HTTP (TCP 80) verso **2.80.200.3**
   * IPsec verso **eFW 2.80.200.2** (UDP 500/4500 + ESP)

---

## Implementazione 

* Default **DROP** su **INPUT/FORWARD**
* **ACCEPT ESTABLISHED,RELATED**
* **GW200**: filtra l’inbound *verso DMZ/eFW* (FORWARD) e lascia passare **solo**:

  * verso **2.80.200.3**: tcp/80, udp+tcp/53
  * verso **2.80.200.2**: udp/500, udp/4500, esp
  
* **eFW**:

  * **INPUT**: permette solo IPsec (udp/500, udp/4500, esp) verso **2.80.200.2**
  * **FORWARD**: permette LAN1↔LAN3 *solo via tunnel* (AV ↔ central-node), blocca AV verso tutto il resto
  * **MASQUERADING**: permette instradamento su internet sostituendo il proprio indirizzo pubblico ai pacchetti in uscita.

* **iFW**:

  * permette **LAN2 → fuori** solo stateful
  * blocca LAN2 ↔ LAN1 (quindi LAN-client non parla con gli AV)

---

## Matrice flussi

| Sorgente                 | Destinazione    | Proto/Port             | Esito              | Nodo enforcement                |
| ------------------------ | --------------- | ---------------------- | ------------------ | ------------------------------- |
| Esterno                  | **2.80.200.3**  | tcp/80                 | ALLOW              | **GW200**                       |
| Esterno                  | **2.80.200.3**  | udp/53 + tcp/53        | ALLOW              | **GW200**                       |
| Esterno                  | **2.80.200.2**  | udp/500, udp/4500, ESP | ALLOW              | **GW200 + eFW(INPUT)**          |
| **10.200.2.10**          | Esterno + DMZ   | any                    | ALLOW **stateful** | **iFW (+ eFW/GW200)**           |
| **10.200.1.11-13** (AV)  | **10.202.3.10** | (servizi AV)           | ALLOW              | **eFW**                         |
| **10.200.1.11-13** (AV)  | altro           | any                    | DENY               | **eFW/iFW**                     |

---

