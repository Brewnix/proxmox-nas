#!/usr/bin/env python3
"""
Proxmox NAS Web UI
GitOps-driven management interface for Proxmox NAS systems
"""

import os
import yaml
import json
import subprocess
from datetime import datetime
from flask import Flask, render_template, request, jsonify, flash, redirect, url_for
from pathlib import Path

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key')

# Configuration
CONFIG_DIR = Path('/opt/brewnix/config/sites')
USB_DIR = Path('/opt/brewnix/bootstrap')
REPO_DIR = Path('/opt/brewnix')

@app.route('/')
def dashboard():
    """Main dashboard showing system status"""
    try:
        # Get system information
        system_info = get_system_info()

        # Get VM/container status
        vm_status = get_proxmox_status()

        # Get recent GitOps activity
        git_status = get_git_status()

        return render_template('dashboard.html',
                             system_info=system_info,
                             vm_status=vm_status,
                             git_status=git_status)
    except Exception as e:
        return render_template('error.html', error=str(e))

@app.route('/sites')
def sites():
    """Site configuration management"""
    sites = []
    if CONFIG_DIR.exists():
        for config_file in CONFIG_DIR.glob('*.yml'):
            with open(config_file, 'r') as f:
                config = yaml.safe_load(f)
                config['filename'] = config_file.name
                sites.append(config)

    return render_template('sites.html', sites=sites)

@app.route('/sites/new', methods=['GET', 'POST'])
def new_site():
    """Create new site configuration"""
    if request.method == 'POST':
        site_config = {
            'site_name': request.form['site_name'],
            'network': {
                'vlan_id': int(request.form['vlan_id']),
                'ip_range': request.form['ip_range']
            },
            'storage': {
                'system_disks': request.form.getlist('system_disks'),
                'data_disks': request.form.getlist('data_disks'),
                'raid_level': request.form['raid_level']
            },
            'proxmox': {
                'api_host': request.form['api_host'],
                'api_user': request.form['api_user']
            }
        }

        # Save configuration
        config_file = CONFIG_DIR / f"{request.form['site_name']}.yml"
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)

        with open(config_file, 'w') as f:
            yaml.dump(site_config, f, default_flow_style=False)

        flash('Site configuration created successfully!')
        return redirect(url_for('sites'))

    return render_template('site_form.html')

@app.route('/usb/create', methods=['POST'])
def create_usb():
    """Generate USB bootstrap drive"""
    site_name = request.form['site_name']
    usb_device = request.form['usb_device']

    try:
        # Run USB creation script
        result = subprocess.run([
            '/opt/brewnix/vendor/proxmox-nas/bootstrap/create-nas-usb.sh',
            '--site-config', f'/opt/brewnix/config/sites/{site_name}.yml',
            '--usb-device', usb_device
        ], capture_output=True, text=True, cwd='/opt/brewnix')

        if result.returncode == 0:
            flash('USB bootstrap drive created successfully!')
        else:
            flash(f'Error creating USB drive: {result.stderr}', 'error')

    except Exception as e:
        flash(f'Error: {str(e)}', 'error')

    return redirect(url_for('sites'))

@app.route('/deploy', methods=['POST'])
def deploy():
    """Trigger GitOps deployment"""
    try:
        # Run Ansible deployment
        result = subprocess.run([
            'ansible-playbook',
            '/opt/brewnix/vendor/proxmox-nas/ansible/site.yml',
            '-e', f'site_config_file=/opt/brewnix/config/sites/{request.form["site_name"]}.yml'
        ], capture_output=True, text=True, cwd='/opt/brewnix')

        if result.returncode == 0:
            flash('Deployment completed successfully!')
        else:
            flash(f'Deployment failed: {result.stderr}', 'error')

    except Exception as e:
        flash(f'Error: {str(e)}', 'error')

    return redirect(url_for('dashboard'))

@app.route('/api/status')
def api_status():
    """API endpoint for system status"""
    return jsonify(get_system_info())

@app.route('/api/vms')
def api_vms():
    """API endpoint for VM/container status"""
    return jsonify(get_proxmox_status())

def get_system_info():
    """Get basic system information"""
    try:
        # ZFS pool status
        zfs_result = subprocess.run(['zpool', 'status', '-j'], capture_output=True, text=True)
        zfs_status = json.loads(zfs_result.stdout) if zfs_result.returncode == 0 else {}

        # Disk usage
        df_result = subprocess.run(['df', '-h', '/'], capture_output=True, text=True)
        disk_usage = df_result.stdout.strip()

        # Memory usage
        mem_result = subprocess.run(['free', '-h'], capture_output=True, text=True)
        memory = mem_result.stdout.strip()

        return {
            'hostname': os.uname().nodename,
            'zfs_pools': zfs_status,
            'disk_usage': disk_usage,
            'memory': memory,
            'timestamp': datetime.now().isoformat()
        }
    except Exception as e:
        return {'error': str(e)}

def get_proxmox_status():
    """Get Proxmox VM/container status"""
    try:
        # This would use the Proxmox API in a real implementation
        # For now, return mock data
        return {
            'vms': [
                {'name': 'truenas', 'status': 'running', 'vmid': 100},
                {'name': 'nextcloud', 'status': 'running', 'vmid': 101}
            ],
            'containers': [
                {'name': 'monitoring', 'status': 'running', 'vmid': 200}
            ]
        }
    except Exception as e:
        return {'error': str(e)}

def get_git_status():
    """Get Git repository status"""
    try:
        # Git status
        status_result = subprocess.run(['git', 'status', '--porcelain'],
                                     capture_output=True, text=True, cwd=REPO_DIR)
        git_status = status_result.stdout.strip()

        # Recent commits
        log_result = subprocess.run(['git', 'log', '--oneline', '-5'],
                                  capture_output=True, text=True, cwd=REPO_DIR)
        recent_commits = log_result.stdout.strip()

        return {
            'status': git_status,
            'recent_commits': recent_commits.split('\n') if recent_commits else []
        }
    except Exception as e:
        return {'error': str(e)}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
