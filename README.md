# Proxmox NAS

**Enterprise-grade NAS infrastructure with automated GitOps deployment**

A Proxmox-based NAS solution featuring **TrueNAS** with direct ZFS access, providing storage for VMs and containers with optional services like Nextcloud, Coder, Kubo, Memos, and GitLab.

## 🚀 Quick Start

### Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- 16GB+ RAM, 100GB+ SSD for system
- Multiple HDDs/SSDs for ZFS storage pool
- Network access for downloading images

### 1. Bootstrap with USB

```bash
# Create bootable USB with automated setup
./bootstrap/create-nas-usb.sh

# Boot target system from USB
# System will auto-configure and register with GitHub
```

### 2. GitOps Deployment

The system automatically:

- Configures ZFS storage pools
- Deploys TrueNAS VM with direct ZFS passthrough
- Sets up optional services (Nextcloud, Coder, etc.)
- Registers for automated updates via GitHub Actions

## 🏗️ Architecture

### Storage Design

```text
Proxmox Host
├── System Pool (SSD): OS, VMs, containers
├── Data Pool (HDD/SSD): ZFS datasets for NAS
│   ├── nas-data: TrueNAS VM storage
│   ├── vm-storage: VM disks
│   ├── container-storage: Container volumes
│   └── backup: Automated backups
└── Network: VLAN-isolated storage network
```

### Service Stack

- **TrueNAS**: Primary NAS with ZFS management
- **Nextcloud**: File sharing and collaboration
- **Coder/Code Server**: Cloud IDE
- **Kubo**: IPFS node
- **Memos**: Note-taking service
- **GitLab**: Self-hosted Git platform

## 📁 Directory Structure

```text
vendor/proxmox-nas/
├── bootstrap/           # USB bootstrap automation
├── ansible/            # Infrastructure deployment
├── terraform/          # VM/container provisioning
├── scripts/            # Management utilities
├── config/             # Configuration templates
├── docs/               # Documentation
└── tests/              # Validation tests
```

## 🔧 Key Features

- **🎯 Automated GitOps Onboarding**: USB boot automatically configures and registers system
- **💾 ZFS Integration**: Direct passthrough to TrueNAS VM
- **🌐 Service Mesh**: Optional containerized services
- **🔄 Auto-Updates**: GitHub Actions for automated deployments
- **📊 Monitoring**: Integrated logging and metrics
- **🛡️ Security**: VLAN isolation and access controls

## 🚀 Deployment Process

### Phase 1: Hardware Bootstrap

1. **USB Creation**: Generate bootable USB with site-specific config
2. **Auto-Setup**: System configures disks, network, and registers with GitHub
3. **Validation**: Automated health checks and connectivity tests

### Phase 2: Service Deployment

1. **TrueNAS VM**: Deploy with ZFS passthrough
2. **Storage Setup**: Configure datasets and shares
3. **Optional Services**: Deploy selected containers
4. **Integration**: Configure service mesh and networking

### Phase 3: GitOps Operation

1. **Automated Updates**: GitHub Actions for deployments
2. **Monitoring**: Centralized logging and alerting
3. **Backup**: Automated ZFS snapshots and replication

## ⚙️ Configuration

### Site Configuration

```yaml
site:
  name: "nas-primary"
  storage:
    system_disks: ["/dev/sda"]
    data_disks: ["/dev/sdb", "/dev/sdc", "/dev/sdd"]
    raid_level: "raidz1"
  network:
    vlan_id: 20
    ip_range: "10.1.20.0/24"
  services:
    truenas: true
    nextcloud: true
    coder: true
```

### Service Configuration

Each service has its own configuration template with environment-specific settings.

## 🔒 Security

- **Network Isolation**: VLAN separation for storage traffic
- **Access Control**: Role-based permissions for services
- **Encryption**: ZFS encryption for data at rest
- **Monitoring**: Security event logging and alerting

## 📊 Monitoring

- **System Health**: Proxmox host monitoring
- **Storage**: ZFS pool and dataset metrics
- **Services**: Application-specific monitoring
- **Network**: Traffic analysis and alerting

## 🛠️ Development

### Local Testing

```bash
# Run validation tests
./tests/validate-config.sh

# Test deployment locally
./scripts/deploy-local.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Configuration Reference](docs/CONFIG.md)
- [Service Integration](docs/SERVICES.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

**Status**: In Development - Reference implementation for improved GitOps design
