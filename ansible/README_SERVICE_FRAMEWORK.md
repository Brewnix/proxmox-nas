# Proxmox Service Management Framework

This framework provides an expandable, reusable system for deploying and managing VMs and containers across different Proxmox server types. The framework is designed to be easily adaptable to various use cases while maintaining consistency and best practices.

## Overview

The service management framework consists of:

- **Universal Service Deployment**: A single deployment task that can handle both VMs and containers
- **Expandable Service Definitions**: YAML-based service definitions that can be easily extended
- **Reusable Across Server Types**: The same framework works for NAS, K3S, development, and other server types
- **Community Repository Support**: Uses Proxmox community repositories instead of enterprise subscriptions
- **Subscription Nag Suppression**: Automatically removes the Proxmox subscription warning screen
- **Integrated Monitoring**: Built-in support for Prometheus, Grafana, and health checks
- **Automated Backup**: Configurable backup schedules and retention policies
- **Network Management**: Flexible network configuration with VLAN and bridge support

## Architecture

```text
├── roles/
│   ├── proxmox_host_setup/           # Host configuration with community repos
│   ├── proxmox_vm_management/        # VM/Container management with service framework
│   └── service_management/           # Universal service management
│       ├── tasks/
│       │   ├── main.yml             # Service deployment orchestration
│       │   ├── deploy_service.yml   # Universal service deployment
│       │   ├── configure_networking.yml
│       │   ├── configure_monitoring.yml
│       │   └── configure_backup.yml
│       ├── templates/
│       └── handlers/
└── services/                        # Service definition files
    └── nas-services.yml              # NAS-specific services
```

## Service Definition Format

Services are defined in YAML files with the following structure:

```yaml
service_name:
  enabled: true/false                 # Whether to deploy this service
  type: vm|container                  # Service type
  vmid: 100                          # Unique VM/Container ID
  template: template-name             # Base template to use
  
  resources:                          # Resource allocation
    cpu: 2
    memory: 4096                      # Memory in MB
    storage: 80                       # Storage in GB
    
  network:                           # Network configuration
    ip: dhcp|static_ip               # IP configuration
    bridge: vmbr0                    # Network bridge
    vlan: 100                        # Optional VLAN
    
  volumes:                           # Volume mounts (containers)
    - "/host/path:/container/path"
    
  ports:                             # Port mappings
    - "host_port:container_port"
    
  monitoring:                        # Monitoring configuration
    enabled: true/false
    port: 9100                       # Metrics port
    metrics_path: /metrics           # Metrics endpoint
    
  backup:                            # Backup configuration
    enabled: true/false
    schedule:                        # Cron-style schedule
      hour: 2
      minute: 0
    retention_days: 30
    storage: local                   # Backup storage
    
  health_check:                      # Health monitoring
    enabled: true/false
    port: 80
    path: /health
```

## Supported Service Types

### Proxmox NAS Services

- **TrueNAS**: Network-attached storage VM
- **Proxmox Backup Server**: Backup solution VM
- **Nextcloud**: File sharing and collaboration
- **Coder**: Development environments
- **Memos**: Note-taking application
- **GitLab**: Git repository and CI/CD
- **Jellyfin**: Media streaming server
- **Pi-hole**: Network-wide ad blocking

### Kubernetes (K3S) Services

- **K3S Master**: Kubernetes control plane
- **K3S Worker**: Kubernetes worker nodes
- **Longhorn Storage**: Distributed storage
- **Rancher Management**: Kubernetes management UI
- **ArgoCD**: GitOps deployment tool
- **Container Registry**: Private Docker registry

### Development Services


- **VS Code Server**: Browser-based IDE
- **Jupyter Lab**: Data science environment
- **Development Desktop**: Full desktop environment
- **Git Server**: Self-hosted Git repositories
- **Database Development**: PostgreSQL, MySQL, Redis

## Usage

### 1. Configure Services

Edit the appropriate service definition file (e.g., `services/proxmox-nas.yml`):

```yaml
truenas:
  enabled: true
  type: vm
  vmid: 100
  # ... other configuration
```

### 2. Deploy Services

Run the main playbook:

```bash
ansible-playbook -i inventory site.yml \
  --extra-vars "proxmox_api_password=your_password"
```

### 3. Deploy Specific Service Types

Use tags to deploy only specific types of services:

```bash
# Deploy only VM management
ansible-playbook site.yml --tags vm_management

# Deploy only monitoring configuration
ansible-playbook site.yml --tags monitoring

# Deploy only backup configuration
ansible-playbook site.yml --tags backup
```

### 4. Add New Services

To add a new service type:

1. Add the service definition to the appropriate YAML file
2. Optionally create a new service file for a different server type
3. Run the playbook - the framework will automatically deploy the new service

## Expandability

### Adding New Server Types

1. Create a new service definition file (e.g., `services/media-server.yml`)
2. Define services specific to that server type
3. Update the main playbook to include the new service file
4. The existing framework will handle all deployment, monitoring, and backup tasks

### Adding New Service Types

The framework can easily accommodate new service types:

```yaml
new_application:
  enabled: true
  type: vm  # or container
  vmid: 999
  template: custom-template
  # All standard configuration options available
```

### Custom Templates

Create custom templates for specific applications:

```yaml
custom_service:
  enabled: true
  type: vm
  template: my-custom-template
  custom_config:
    feature_a: enabled
    feature_b: disabled
  # Framework will pass through custom configuration
```

## Community Repository Configuration

The framework automatically configures Proxmox to use community repositories instead of enterprise ones:

- Removes enterprise repository files
- Configures community APT sources
- Updates package cache
- Installs required packages from community repos
- **Suppresses subscription nag screen** for a seamless experience

### Subscription Nag Suppression

The framework automatically removes the subscription warning that appears in the Proxmox web interface:

- **Safe modification**: Backs up original files before changes
- **Multiple methods**: Uses several techniques to ensure complete suppression
- **Verification tools**: Includes scripts to verify and restore if needed
- **Browser cache handling**: Provides instructions for clearing cache

To disable nag suppression (if needed):
```yaml
suppress_subscription_nag: false
```

Verification and restore scripts:
- `/usr/local/bin/verify-nag-suppression.sh` - Check if suppression worked
- `/usr/local/bin/restore-nag-screen.sh` - Restore original behavior

This ensures the system works without Proxmox subscriptions while maintaining full functionality.

## Monitoring Integration

Services automatically integrate with monitoring systems:

- **Prometheus**: Automatic target configuration
- **Grafana**: Dashboard generation
- **Health Checks**: Automated service monitoring
- **Alerting**: Configurable alert rules

## Backup Management

Comprehensive backup solution:

- **VM Backups**: Full VM snapshots using vzdump
- **Container Backups**: LXC container backups
- **Data Volume Backups**: Application data backups
- **Retention Management**: Automatic cleanup of old backups
- **Verification**: Backup integrity checks

## Network Configuration

Flexible networking options:

- **Bridge Management**: Automatic bridge configuration
- **VLAN Support**: VLAN-aware networking
- **Firewall Rules**: Service-specific firewall configuration
- **DNS Management**: Automatic DNS configuration

## Best Practices

1. **Service IDs**: Use consistent VMID ranges for different service types
2. **Resource Planning**: Plan CPU and memory allocation carefully
3. **Network Segmentation**: Use VLANs for security
4. **Backup Strategy**: Enable backups for critical services
5. **Monitoring**: Enable monitoring for all production services
6. **Documentation**: Document custom service configurations

## Troubleshooting

### Common Issues

1. **Service Deployment Fails**: Check VMID conflicts and resource availability
2. **Network Issues**: Verify bridge and VLAN configuration
3. **Template Missing**: Ensure required templates are available
4. **API Access**: Verify Proxmox API credentials and permissions

### Logs

- Deployment logs: `/var/log/proxmox-nas-deployment.log`
- Service status: `/root/service-management-status.yml`
- Ansible logs: Standard Ansible logging

## Contributing

To extend the framework:

1. Add new service definitions following the existing format
2. Create new service files for different server types
3. Add custom templates as needed
4. Test thoroughly before deploying to production

The framework is designed to be self-extending - adding new services should require minimal changes to the core framework code.
