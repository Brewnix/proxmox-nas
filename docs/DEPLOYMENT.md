# Proxmox NAS GitOps Deployment Guide

This guide explains the improved GitOps approach for deploying Proxmox NAS systems with automated onboarding and unified management.

## Overview

The new design eliminates the split between "baremetal deployment" and "local management" scripts, providing a unified GitOps workflow that:

- Automates system onboarding via USB boot
- Configures ZFS storage pools automatically
- Deploys services through a single Ansible playbook
- Maintains GitOps principles throughout the lifecycle

## Architecture Improvements

### Before (Old Design)

```text
Baremetal Setup → Local Scripts → Manual GitOps Setup
     ↓                    ↓                    ↓
USB Bootstrap    Proxmox-local/     Manual Config
```

### After (New Design)

```text
Automated Onboarding → Unified Deployment → GitOps Operation
     ↓                            ↓                    ↓
USB Bootstrap           Single Playbook      Auto-Updates
```

## Deployment Process

### Phase 1: USB Bootstrap

1. **Create Site Configuration**

   ```bash
   cp vendor/proxmox-nas/config/site-example.yml config/sites/nas-site.yml
   # Edit configuration for your environment
   ```

2. **Generate USB Boot Drive**

   ```bash
   ./vendor/proxmox-nas/bootstrap/create-nas-usb.sh \
     --site-config config/sites/nas-site.yml \
     --usb-device /dev/sdb \
     --github-token YOUR_GITHUB_TOKEN
   ```

3. **Boot Target System**

   - Insert USB drive
   - Configure BIOS to boot from USB
   - Install Proxmox using the standard Proxmox installer
   - **Important**: Do NOT install to the data disks - use system disks only
   - After installation completes, run the post-install script:

     ```bash
     mount /dev/sdb2 /mnt
     sudo /mnt/post-install.sh
     ```

   - The bootstrap script will automatically:
     - Configure disks and ZFS pools
     - Set up GitOps authentication
     - Clone repository
     - Register for automated updates

### Phase 2: Service Deployment

1. **Run Unified Deployment**

   ```bash
   cd /opt/brewnix
   ansible-playbook vendor/proxmox-nas/ansible/site.yml
   ```

2. **Monitor Deployment**

   ```bash
   tail -f /var/log/proxmox-nas-deployment.log
   ```

### Phase 3: GitOps Operation

The system is now under full GitOps control:

- **Automated Updates**: GitHub Actions deploy changes
- **Configuration Management**: All config in Git
- **Monitoring**: Integrated health checks
- **Backup**: Automated ZFS snapshots

## Configuration Structure

### Site Configuration (`config/sites/nas-site.yml`)

```yaml
site_name: "nas-primary"
storage:
  # Basic configuration
  system_disks: ["/dev/sda"]
  data_disks: ["/dev/sdb", "/dev/sdc", "/dev/sdd"]
  raid_level: "raidz1"
  
  # Advanced options
  system_raid: "mirror"  # Optional: "mirror" for system disk redundancy
  hot_spare_disks: ["/dev/sde"]  # Optional: hot spares for automatic replacement
  slog_devices: ["/dev/nvme0n1"]  # Optional: ZIL/SLOG for write performance
  l2arc_devices: ["/dev/nvme1n1"]  # Optional: L2ARC for read caching
  
network:
  vlan_id: 20
  ip_range: "10.1.20.0/24"
services:
  truenas: true
  nextcloud: true
  coder: true
```

### USB Bootstrap Configuration

The USB drive contains:

- Proxmox ISO installation files
- Site-specific settings
- GitHub authentication token
- Post-install bootstrap scripts

## Key Improvements

### 1. Automated GitOps Onboarding

- USB boot automatically configures GitHub access
- No manual SSH key setup required
- Repository cloned and configured automatically

### 2. Unified Deployment

- Single Ansible playbook for all components
- No separate baremetal/local script split
- Consistent configuration management

### 3. ZFS Integration

- Direct passthrough to TrueNAS VM
- Automated pool and dataset creation
- Health monitoring and snapshots

### 4. Service Mesh

- Optional containerized services
- Network isolation and security
- Easy scaling and updates

## Troubleshooting

### Bootstrap Issues

```bash
# Check bootstrap logs
tail -f /var/log/nas-bootstrap.log

# Verify USB creation
lsblk  # Check partitions
mount /dev/sdb2 /mnt && ls /mnt  # Check contents
```

### Deployment Issues

```bash
# Check Ansible logs
tail -f /var/log/ansible.log

# Verify ZFS pools
zpool status
zfs list

# Check service status
systemctl status proxmox-nas-*
```

### GitOps Issues

```bash
# Check GitHub connectivity
ssh -T git@github.com

# Verify repository
cd /opt/brewnix && git status

# Check automation logs
tail -f /var/log/github-actions.log
```

## Migration from Old Design

### For Existing Systems

1. Backup current configuration
2. Generate new USB with site config
3. Boot and run unified deployment
4. Migrate services to new structure

### For New Deployments

1. Use the new USB bootstrap process
2. Configure services in site YAML
3. Deploy with single playbook

## Best Practices

### Storage Planning

- Use SSDs for system pool
- Plan RAID level based on disk count
- Reserve space for snapshots (20-30%)

### Network Design

- Use VLAN isolation for storage traffic
- Configure jumbo frames if possible
- Plan for service accessibility

### Security

- Use GitHub tokens with minimal permissions
- Enable ZFS encryption for sensitive data
- Configure firewall rules appropriately

### Monitoring

- Set up email alerts for ZFS issues
- Monitor disk usage and performance
- Regular backup verification

## Support

For issues with the new design:

1. Check the troubleshooting section above
2. Review logs in `/var/log/`
3. Verify configuration in `/opt/brewnix/config/`
4. Check GitHub repository for updates

---

## New Features Overview

### ✅ **Proxmox-Specific Ansible Integration**

- **Full Proxmox API support** using `community.general` collection
- **VM/Container lifecycle management** through GitOps
- **Storage and network configuration** via Ansible modules
- **Backup and snapshot automation** integrated with GitOps

### ✅ **Advanced Storage Configuration**

- **ZFS native management** with performance optimizations
- **SLOG devices** for write caching (NVMe SSD recommended)
- **L2ARC devices** for read caching (NVMe SSD recommended)
- **Hot spare disks** for automatic replacement
- **Linux RAID mirroring** for system disk redundancy

### ✅ **GitOps-Driven VM Management**

- **Declarative VM/container definitions** in YAML
- **Automated deployment and updates** through Git
- **Snapshot and backup integration** with GitOps workflow
- **Service mesh and networking** configuration

### ✅ **Web UI for User Interaction**

- **Site configuration management** through web interface
- **Real-time system monitoring** and status
- **USB key generation** for new deployments
- **GitOps deployment triggers** and rollback capabilities
- **Local notifications** for updates and maintenance

### ✅ **Enterprise-Ready Features**

- **Multi-site support** with shared configurations
- **Automated backup schedules** and retention policies
- **Monitoring and alerting** integration
- **Security hardening** and compliance features
