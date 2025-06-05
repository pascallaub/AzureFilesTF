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

## Lokales Testing (ohne Azure-Berechtigungen)

Dieses Projekt kann vollständig lokal getestet werden, um die Terraform-Konfiguration zu validieren, ohne tatsächlich Azure-Ressourcen zu erstellen.

### **Warum lokales Testing?**

-  **Syntax-Validierung** ohne Cloud-Zugriff
-  **Module-Struktur prüfen** vor Deployment
-  **Entwicklungszeit sparen** durch frühe Fehlererkennung
-  **CI/CD Pipeline Integration** für Code-Quality-Checks
-  **Kosten vermeiden** durch Validierung ohne Ressourcen-Erstellung

### **Kompletter Lokaler Test**

```bash
# Kompletten Test-Suite ausführen
cd ~/TechstarterWorkspace/azureFileshare/environments/dev

# 1. Syntax-Validierung
echo "=== 1. Syntax-Validierung ==="
terraform validate

# 2. Code-Formatierung prüfen
echo "=== 2. Formatierung prüfen ==="
terraform fmt -check -recursive ../../

# 3. Terraform initialisieren (lokaler State)
echo "=== 3. Initialisierung ==="
terraform init

# 4. Provider und Module-Struktur prüfen
echo "=== 4. Module-Struktur prüfen ==="
terraform providers

# 5. Deployment-Plan generieren (ohne Ausführung)
echo "=== 5. Plan-Struktur testen ==="
export ARM_SUBSCRIPTION_ID="your-subscription-id"
terraform plan -input=false

echo "=== Test abgeschlossen ==="
```

### **Erwartete Test-Ergebnisse**

#### **Erfolgreiche Outputs:**

```bash
# Syntax-Validierung
Success! The configuration is valid.

# Initialisierung
Terraform has been successfully initialized!

# Provider-Struktur
Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/azurerm] ~> 4.0
├── module.network
│   └── provider[registry.terraform.io/hashicorp/azurerm]
└── module.storage
    └── provider[registry.terraform.io/hashicorp/azurerm]

# Plan-Generierung
Plan: 8 to add, 0 to change, 0 to destroy.
```

#### **Erwartete Warnings:**

```bash
# Code-Formatierung (optional zu beheben)
provider.tf
terraform fmt -write=true ../../**/*.tf

# Azure-Berechtigungen (erwartet bei realem Deployment)
Error: AuthorizationFailed
```

### **Einzelne Test-Schritte**

#### **1. Syntax-Validierung**

```bash
cd environments/dev
terraform validate
# Prüft: HCL-Syntax, Variable-Referenzen, Resource-Definitionen
```

#### **2. Code-Formatierung**

```bash
terraform fmt -check -recursive ../../
# Prüft: Terraform Code-Style, Einrückungen, Struktur

# Automatische Formatierung (optional)
terraform fmt -write=true ../../**/*.tf
```

#### **3. Module-Validierung**

```bash
# Network-Modul einzeln testen
cd ../../modules/network
terraform validate

# Storage-Modul einzeln testen
cd ../storage
terraform validate
```

#### **4. Provider-Dependencies**

```bash
cd ../../environments/dev
terraform providers
# Zeigt: Provider-Hierarchie, Versionen, Module-Dependencies
```

#### **5. Plan-Generierung**

```bash
terraform init
terraform plan -out=test.tfplan
terraform show test.tfplan
# Generiert: Deployment-Plan ohne Ausführung
```

### **Test-Integration in Development Workflow**

#### **Git Pre-Commit Hook**

```bash
#!/bin/bash
# .git/hooks/pre-commit
cd environments/dev
terraform fmt -check -recursive ../../ || exit 1
terraform validate || exit 1
echo "Terraform validation passed"
```

#### **CI/CD Pipeline Integration**

```yaml
# GitHub Actions / Azure DevOps
steps:
  - name: Terraform Validation
    run: |
      cd environments/dev
      terraform init
      terraform validate
      terraform plan -input=false
```

#### **IDE Integration (VS Code)**

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Terraform Validate",
      "type": "shell",
      "command": "terraform",
      "args": ["validate"],
      "group": "test"
    }
  ]
}
```

### **Test-Quality Gates**

| Test          | Zweck           | Erfolgs-Kriterium                           |
| ------------- | --------------- | ------------------------------------------- |
| **Syntax**    | HCL-Korrektheit | `Success! The configuration is valid.`      |
| **Format**    | Code-Style      | Keine Format-Warnings                       |
| **Init**      | Provider-Setup  | `Successfully initialized!`                 |
| **Providers** | Dependencies    | Korrekte Provider-Hierarchie                |
| **Plan**      | Resource-Logik  | `Plan: X to add, 0 to change, 0 to destroy` |

### **Troubleshooting lokaler Tests**

#### **Häufige Probleme:**

1. **Terraform Version**

   ```bash
   terraform version
   # Mindestens: Terraform v1.6.0
   ```

2. **Module-Pfade**

   ```bash
   # Prüfen ob Module-Verzeichnisse existieren
   ls -la ../../modules/
   ```

3. **Provider-Cache**

   ```bash
   # Provider-Cache löschen bei Problemen
   rm -rf .terraform/
   terraform init
   ```

4. **Formatierung-Fixes**
   ```bash
   # Automatische Formatierung
   terraform fmt -recursive ../../
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

- **Sofort einsatzbereit** - Keine Backend-Setup erforderlich
- **Schnelle Entwicklung** - Kein Netzwerk-Overhead
- **Keine Berechtigungen** - Funktioniert ohne Backend-Zugriff
- **Offline-Fähigkeit** - Arbeiten ohne Internet möglich

**Nachteile:**

- **Keine Team-Kollaboration** - State nur lokal verfügbar
- **Kein State-Locking** - Concurrent-Access Probleme möglich
- **Backup-Risiko** - State geht bei PC-Verlust verloren

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

- **Team-Kollaboration** - Zentraler State für alle
- **State-Locking** - Verhindert Concurrent-Änderungen
- **Backup & Recovery** - Azure-native Redundanz
- **Audit-Trail** - Vollständige Änderungshistorie
- **CI/CD Integration** - Pipeline-freundlich

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
-  **Lokales Testing** für schnelle Entwicklung
-  **Code-Quality Gates** in CI/CD Pipelines
