# Stageopdracht: Security Scanning Applicatie
Deze applicatie bied inzicht in de beveiliging van een OpenShift containerplatform.

Dit wordt gerealiseerd door security scanning uit te voeren met de volgende tools:
- Kube-Hunter (https://github.com/aquasecurity/kube-hunter)
- Polaris (https://github.com/FairwindsOps/polaris)
- Quay Container Security Operator (https://github.com/quay/container-security-operator)

# Requirements aan het OpenShift containerplatform:
- Gebruiker met cluster-amdmin rol voor installatie.
- Mogelijkheid om log bestanden van het containerplatform naar externe pc te sturen.
- Internet toegang of proxy

# Installatie:
 1) Pull deze repository naar het containerplatform. 
 2) start het startsecurityscanner.sh script direct op het containerplatfrom (dus niet in een container).

Dit script zal Kube-Hunter, Polaris en Quay Container Security Operator installeren aan de hand van meegeleverde yaml files.
Vervolgens zal script de log bestanden verzamelen en in een map opslaan.

Om de log bestanden grafisch weer te geven met een Kibana dashboard is de volgende repository opgezet: https://github.com/TheChrisKip/KibanaDashboardSecurityScanner
