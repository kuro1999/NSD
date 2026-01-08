# Submission checklist

## Deliverables
- [ ] README completo (root)
- [ ] Documentazione in `docs/` completa e consistente
- [ ] Configurazioni in `configs/` (dump o file config)
- [ ] Evidenze test in `evidence/`
- [ ] Esportazione progetto GNS3 o dump configurazioni persistenti
- [ ] Nessuna immagine docker inclusa nel pacchetto

## Coerenza
- [ ] Addressing plan coerente con config effettive
- [ ] Routing (OSPF/iBGP/eBGP/static) coerente con reachability
- [ ] DNS/DNSSEC funzionante
- [ ] Firewall rispettano la policy (test negativi inclusi)
- [ ] IPsec enterprise e customer funzionanti
- [ ] MACsec con MKA in Site2 funzionante
- [ ] Sandbox AV: 3 runner, central orchestration, report, reset runner

## Packaging
- [ ] Zip del repo + export GNS3/config (come richiesto)
- [ ] Nomi file e cartelle chiari e senza ambiguità