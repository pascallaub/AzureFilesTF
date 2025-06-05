# Azure Files mit Private Endpoint - Terraform Infrastructure

## Use Case

Dieses Projekt implementiert eine **sichere Azure Files-Lösung** mit Private Endpoints in einem geschützten Netzwerk. Die Infrastruktur ermöglicht sicheren Dateizugriff ohne Exposition zum Internet.

### Geschäftlicher Nutzen

- **Sichere Dateifreigabe** zwischen Azure-Ressourcen
- **Private Netzwerkkonnektivität** ohne Internet-Routing
- **Compliance-konforme** Lösung für sensible Daten
- **Skalierbare Architektur** für Enterprise-Umgebungen

## Architektur

```
┌─────────────────────────────────────────────────────────┐
│                 Azure Subscription                      │
│  ┌─────────────────────────────────────────────────────┐│
│  │            Resource Group                           ││
│  │   ┌─────────────────┐    ┌─────────────────────────┐││
│  │   │  Virtual Network│    │   Storage Account       │││
│  │   │   10.0.0.0/16   │    │   - File Share (100GB)  │││
│  │   │                 │    │   - LRS Replication     │││
│  │   │  ┌─────────────┐│    │   - HTTPS Only          │││
│  │   │  │Private Subnet│    └─────────────────────────┘││
│  │   │  │10.0.1.0/24  ││                 │             ││
│  │   │  └─────────────┘│                 │             ││
│  │   └─────────────────┘                 │             ││
│  │           │                           │             ││
│  │           └───────Private Endpoint────┘             ││
│  │                                                     ││
│  │  ┌─────────────────────────────────────────────────┐││
│  │  │        Private DNS Zone                         │││
│  │  │    privatelink.file.core.windows.net            │││
│  │  └─────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## Projekt-Struktur

```
azureFileshare/
├── modules/
│   ├── network/                 # Netzwerk-Komponenten
│   │   ├── main.tf             # VNet, Subnet, DNS
│   │   ├── variables.tf        # Input-Variablen
│   │   └── outputs.tf          # Ausgabe-Werte
│   └── storage/                # Storage-Komponenten
│       ├── main.tf             # Storage Account, File Share, Private Endpoint
│       ├── variables.tf        # Input-Variablen
│       └── outputs.tf          # Ausgabe-Werte
├── environments/
│   ├── dev/                    # Development-Umgebung
│   │   ├── main.tf             # Modul-Aufrufe
│   │   ├── variables.tf        # Umgebungs-Variablen
│   │   ├── terraform.tfvars    # Umgebungs-Werte
│   │   └── provider.tf         # Provider-Konfiguration
│   └── prod/                   # Production-Umgebung
│       ├── main.tf             # Modul-Aufrufe
│       ├── variables.tf        # Umgebungs-Variablen
│       ├── terraform.tfvars    # Umgebungs-Werte
│       └── provider.tf         # Provider-Konfiguration
├── backend.tf                  # Remote State Backend (optional)
├── versions.tf                 # Terraform/Provider Versionen
├── .gitignore                  # Git-Ausschlüsse
└── README.md                   # Diese Dokumentation
```

## Technische Spezifikationen

### Netzwerk-Module

- **Virtual Network**: 10.0.0.0/16 (65,536 IPs)
- **Private Subnet**: 10.0.1.0/24 (256 IPs)
- **Private DNS Zone**: privatelink.file.core.windows.net
- **DNS-VNet Link**: Automatische DNS-Auflösung

### Storage-Module

- **Storage Account**: Standard LRS, HTTPS-only
- **File Share**: 100GB Quota, SMB-Protokoll
- **Private Endpoint**: Sichere Verbindung ohne Internet
- **Network Rules**: Deny Default, Allow Subnet

### Sicherheitsfeatures

-  **Netzwerk-Isolation**: Kein direkter Internet-Zugriff
-  **Private Endpoints**: Interne Azure-Konnektivität
-  **HTTPS Enforcement**: Verschlüsselter Datenverkehr
-  **Subnet Whitelisting**: Zugriffskontrolle auf Netzwerkebene
-  **Private DNS**: Interne Namensauflösung

## State Management

Dieses Projekt unterstützt sowohl lokalen als auch remote State für maximale Flexibilität.

### Lokaler State (Standard - Development)

**Aktuell aktiv** - Ideal für Development und Testing:

```bash
# Konfiguration: backend.tf ist auskommentiert
# terraform {
#   backend "azurerm" { ... }
# }
```

**Vorteile:**

-  **Sofort einsatzbereit** - Keine Backend-Setup erforderlich
-  **Schnelle Entwicklung** - Kein Netzwerk-Overhead
-  **Keine Berechtigungen** - Funktioniert ohne Backend-Zugriff
-  **Offline-Fähigkeit** - Arbeiten ohne Internet möglich

**Nachteile:**

-  **Keine Team-Kollaboration** - State nur lokal verfügbar
-  **Kein State-Locking** - Concurrent-Access Probleme möglich
-  **Backup-Risiko** - State geht bei PC-Verlust verloren

### Remote State (Production-Ready)

**Für Produktionsumgebungen** - Aktivierung durch Auskommentieren:

```hcl
# In backend.tf aktivieren:
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatestorage"
    container_name       = "statefiles"
    key                  = "azurefiles/terraform.tfstate"
  }
}
```

**Vorteile:**

-  **Team-Kollaboration** - Zentraler State für alle
-  **State-Locking** - Verhindert Concurrent-Änderungen
-  **Backup & Recovery** - Azure-native Redundanz
-  **Audit-Trail** - Vollständige Änderungshistorie
-  **CI/CD Integration** - Pipeline-freundlich

**Setup-Schritte für Remote Backend:**

```bash
# 1. Backend-Infrastruktur erstellen
az group create --name tfstate --location westeurope
az storage account create \
  --resource-group tfstate \
  --name tfstatestorage \
  --sku Standard_LRS \
  --kind StorageV2

az storage container create \
  --name statefiles \
  --account-name tfstatestorage

# 2. Backend in backend.tf aktivieren (Kommentare entfernen)

# 3. State migrieren
terraform init -migrate-state
```

### State-Migration (Lokal ↔ Remote)

**Von Lokal zu Remote:**

```bash
# 1. Remote Backend in backend.tf aktivieren
# 2. Migration durchführen
terraform init -migrate-state
# 3. Bestätigen: "yes"
```

**Von Remote zu Lokal:**

```bash
# 1. Backend in backend.tf auskommentieren
# 2. State lokal initialisieren
terraform init -migrate-state
# 3. Bestätigen: "yes"
```

### State-Strategien nach Umgebung

| Environment     | State Type | Begründung                                    |
| --------------- | ---------- | --------------------------------------------- |
| **Development** | Lokal      | Schnelle Iteration, keine Team-Abhängigkeiten |
| **Staging**     | Remote     | Team-Testing, CI/CD Integration               |
| **Production**  | Remote     | Kritische Infrastruktur, Audit-Anforderungen  |

## Deployment

### Voraussetzungen

- Azure CLI installiert und authentifiziert
- Terraform >= 1.6.0
- Azure-Subscription mit entsprechenden Berechtigungen

### Development-Umgebung deployen

```bash
# Zum Dev-Environment wechseln
cd environments/dev

# Azure Subscription ID setzen
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# Terraform initialisieren (Lokaler State)
terraform init

# Deployment planen
terraform plan

# Infrastructure erstellen
terraform apply
```

### Production-Umgebung deployen

```bash
# Zum Prod-Environment wechseln
cd environments/prod

# Azure Subscription ID setzen
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# Terraform initialisieren (Remote State empfohlen)
terraform init

# Deployment planen
terraform plan

# Infrastructure erstellen
terraform apply
```

## Kostenabschätzung

| Komponente                     | Kosten/Monat (EUR) |
| ------------------------------ | ------------------ |
| Storage Account (Standard LRS) | ~2-5               |
| Private Endpoint               | ~6.50              |
| Private DNS Zone               | ~0.45              |
| VNet/Subnets                   | Kostenlos          |
| **Remote State Backend**       | **~0.50**          |
| **Total pro Environment**      | **~9-12**          |

## Monitoring & Management

### Wichtige Outputs

```bash
# Nach dem Deployment verfügbar:
terraform output storage_account_name
terraform output file_share_name
terraform output private_endpoint_ip
terraform output resource_group_name
```

### File Share Zugriff

```bash
# File Share mounten (Windows)
net use Z: \\<storage-account>.file.core.windows.net\data

# File Share mounten (Linux)
sudo mount -t cifs //<storage-account>.file.core.windows.net/data /mnt/fileshare
```

## Troubleshooting

### Häufige Probleme

1. **Berechtigungsfehler**

   ```
   Solution: Azure Contributor-Rolle auf Subscription-Ebene erforderlich
   ```

2. **Provider-Versionskonflikte**

   ```bash
   terraform init -upgrade
   ```

3. **State-Backend nicht verfügbar**

   ```
   Solution: Backend in backend.tf auskommentieren für lokalen State
   ```

4. **State-Lock Probleme**
   ```bash
   # Force-unlock (nur bei hängenden Locks)
   terraform force-unlock <LOCK_ID>
   ```

## Anpassungen

### Neue Umgebung hinzufügen

```bash
# Neues Environment erstellen
mkdir environments/staging
cp environments/dev/* environments/staging/

# terraform.tfvars anpassen
sed -i 's/dev/staging/g' environments/staging/terraform.tfvars
```

### Speicher-Quota ändern

```hcl
# In modules/storage/main.tf
resource "azurerm_storage_share" "share" {
  quota = 500  # Von 100GB auf 500GB
}
```

### Backend für neue Umgebung

```hcl
# Eigener State-Key pro Environment
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatestorage"
    container_name       = "statefiles"
    key                  = "azurefiles/staging/terraform.tfstate"  # Umgebungs-spezifisch
  }
}
```

## Best Practices

-  **Modulare Architektur** für Wiederverwendbarkeit
-  **Environment-Trennung** für sichere Deployments
-  **Version Pinning** für konsistente Builds
-  **Resource Tagging** für Cost Management
-  **Security-First** Design mit Private Endpoints
-  **Infrastructure as Code** für Nachvollziehbarkeit
-  **Remote State** für Produktionsumgebungen
-  **State-Backup** Strategien implementieren

## Support

Bei Fragen oder Problemen:

1. Terraform-Dokumentation konsultieren
2. Azure-Support kontaktieren
3. Issue in diesem Repository erstellen
