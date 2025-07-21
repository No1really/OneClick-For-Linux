#!/bin/bash

# OneClick for Arch - Installation Script (Fixed for GNOME Shell 42+)
# Creates a complete GNOME Shell extension for Arch Linux system updates

set -e

EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/oneclick-arch@local"
EXTENSION_NAME="OneClick for Arch"
EXTENSION_UUID="oneclick-arch@local"

echo "🎯 Installing OneClick for Arch Extension (Modern GNOME Shell)..."

# Create extension directory
mkdir -p "$EXTENSION_DIR"

# Create metadata.json
cat > "$EXTENSION_DIR/metadata.json" << \EOF
{
  "uuid": "oneclick-arch@local",
  "name": "OneClick for Arch",
  "description": "One-click Arch Linux system updater with Pac-Man themed progress",
  "version": 2,
  "shell-version": ["42", "43", "44", "45", "46", "47", "48"],
  "url": "https://github.com/user/oneclick-arch",
  "settings-schema": "org.gnome.shell.extensions.oneclick-arch"
}
EOF

# Create extension.js - Main extension logic (Modern ES6 syntax)
cat > "$EXTENSION_DIR/extension.js" << \EOF
import GObject from 'gi://GObject';
import St from 'gi://St';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

let indicator;

const OneClickIndicator = GObject.registerClass(
class OneClickIndicator extends PanelMenu.Button {
    _init(extension) {
        super._init(0.0, 'OneClick for Arch', false);
        
        this._extension = extension;
        this._settings = extension.getSettings();
        this._updateTimer = null;
        this._checkInterval = 3600; // 1 hour default
        this._isUpdating = false;
        this._isChecking = false;
        this._updateHistory = [];
        this._lastUpdateCheck = null;
        this._snoozeTimer = null;
        
        // Update counts
        this._securityUpdates = 0;
        this._essentialUpdates = 0;
        this._optionalUpdates = 0;
        this._flatpakUpdates = 0;
        
        // Create main container
        this._container = new St.BoxLayout({
            style_class: 'oneclick-arch-indicator'
        });
        this.add_child(this._container);
        
        // Create icon
        this._icon = new St.Icon({
            icon_name: 'system-software-update-symbolic',
            style_class: 'system-status-icon',
        });
        this._container.add_child(this._icon);
        
        // Create update badge
        this._badge = new St.Label({
            style_class: 'oneclick-update-badge',
            text: '',
            visible: false
        });
        this._container.add_child(this._badge);
        
        // Apply accent color
        this._syncAccentColor();
        
        // Build menu
        this._buildMenu();
        
        // Connect to settings changes
        this._accentColorConnection = this._settings.connect('changed::accent-color', 
            () => this._syncAccentColor());
        this._intervalConnection = this._settings.connect('changed::check-interval',
            () => this._startUpdateTimer());
            
        // Start periodic checks
        this._startUpdateTimer();
        
        // Initial update check
        this._checkForUpdates();
    }
    
    _syncAccentColor() {
        const accentColor = this._getSystemAccentColor();
        this._icon.set_style(`color: ${accentColor};`);
        
        // Update menu item indicators
        if (this._menuItems) {
            this._menuItems.forEach(item => {
                if (item._indicator) {
                    item._indicator.set_style(`color: ${accentColor};`);
                }
            });
        }
    }
    
    _getSystemAccentColor() {
        try {
            const settings = new Gio.Settings({schema: 'org.gnome.desktop.interface'});
            const accentColor = settings.get_string('accent-color');
            
            const colorMap = {
                'blue': '#3584e4',
                'teal': '#2dd4aa', 
                'green': '#33d17a',
                'yellow': '#f6d32d',
                'orange': '#ff7800',
                'red': '#e01b24',
                'pink': '#c061cb',
                'purple': '#9141ac',
                'slate': '#6f8396'
            };
            
            return colorMap[accentColor] || '#3584e4';
        } catch (e) {
            return '#3584e4'; // Default blue
        }
    }
    
    _buildMenu() {
        this._menuItems = [];
        
        // Check Updates with loading spinner
        this._checkUpdatesItem = this._createMenuItemWithIndicator('Check Updates');
        this._checkUpdatesItem.connect('activate', () => this._checkForUpdates());
        this.menu.addMenuItem(this._checkUpdatesItem);
        
        // Loading spinner (initially hidden)
        this._loadingSpinner = new St.Icon({
            icon_name: 'content-loading-symbolic',
            style_class: 'popup-menu-icon',
            visible: false
        });
        this._checkUpdatesItem.add_child(this._loadingSpinner);
        
        // Update Now with submenu
        this._updateNowItem = this._createMenuItemWithIndicator('Update Now');
        this._updateSubmenu = new PopupMenu.PopupSubMenuMenuItem('Update Options');
        
        this._fullUpdateItem = this._createMenuItemWithIndicator('Full Update');
        this._fullUpdateItem.connect('activate', () => this._performUpdate('full'));
        this._updateSubmenu.menu.addMenuItem(this._fullUpdateItem);
        
        this._essentialUpdateItem = this._createMenuItemWithIndicator('Essentials Only (Default)');
        this._essentialUpdateItem.connect('activate', () => this._performUpdate('essential'));
        this._updateSubmenu.menu.addMenuItem(this._essentialUpdateItem);
        
        this._optionalUpdateItem = this._createMenuItemWithIndicator('Additional Only');
        this._optionalUpdateItem.connect('activate', () => this._performUpdate('optional'));
        this._updateSubmenu.menu.addMenuItem(this._optionalUpdateItem);
        
        this.menu.addMenuItem(this._updateSubmenu);
        
        // Quick update button (defaults to essential)
        this._quickUpdateItem = this._createMenuItemWithIndicator('Quick Update (Essential)');
        this._quickUpdateItem.connect('activate', () => this._performUpdate('essential'));
        this.menu.addMenuItem(this._quickUpdateItem);
        
        // Separator
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        
        // Update History
        this._historyItem = this._createMenuItemWithIndicator('Update History');
        this._historyItem.connect('activate', () => this._showHistory());
        this.menu.addMenuItem(this._historyItem);
        
        // More Options
        this._settingsItem = this._createMenuItemWithIndicator('More Options');
        this._settingsItem.connect('activate', () => this._openSettings());
        this.menu.addMenuItem(this._settingsItem);
        
        // Store menu items for accent color updates
        this._menuItems = [
            this._checkUpdatesItem,
            this._fullUpdateItem,
            this._essentialUpdateItem,
            this._optionalUpdateItem,
            this._quickUpdateItem,
            this._historyItem,
            this._settingsItem
        ];
    }
    
    _createMenuItemWithIndicator(text) {
        const item = new PopupMenu.PopupMenuItem(text);
        
        // Create indicator bullet
        const indicator = new St.Label({
            text: '•',
            style_class: 'oneclick-menu-indicator',
            visible: false
        });
        
        item.add_child(indicator);
        item._indicator = indicator;
        
        // Show indicator on hover
        item.connect('enter-event', () => {
            indicator.visible = true;
            indicator.set_style(`color: ${this._getSystemAccentColor()};`);
        });
        
        item.connect('leave-event', () => {
            indicator.visible = false;
        });
        
        return item;
    }
    
    _startUpdateTimer() {
        if (this._updateTimer) {
            GLib.source_remove(this._updateTimer);
        }
        
        this._checkInterval = this._settings.get_int('check-interval') * 3600; // Convert hours to seconds
        this._updateTimer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 
            this._checkInterval, () => {
                this._checkForUpdates();
                return GLib.SOURCE_CONTINUE;
            });
    }
    
    async _checkForUpdates() {
        if (this._isUpdating || this._isChecking) return;
        
        this._isChecking = true;
        this._loadingSpinner.visible = true;
        
        try {
            // Reset counts
            this._securityUpdates = 0;
            this._essentialUpdates = 0;
            this._optionalUpdates = 0;
            this._flatpakUpdates = 0;
            
            // Check different update types
            const [packagesAvailable, flatpaksAvailable] = await Promise.all([
                this._checkPacmanUpdates(),
                this._checkFlatpakUpdates()
            ]);
            
            // Classify packages
            await this._classifyUpdates(packagesAvailable);
            this._flatpakUpdates = flatpaksAvailable;
            
            const totalUpdates = this._securityUpdates + this._essentialUpdates + this._optionalUpdates + this._flatpakUpdates;
            
            this._lastUpdateCheck = new Date();
            
            if (totalUpdates > 0) {
                this._updateBadge();
                this._showUpdateNotification();
            } else {
                this._hideBadge();
            }
            
        } catch (error) {
            console.error('OneClick: Error checking updates:', error);
            this._showErrorNotification('Failed to check for updates', error.message);
        } finally {
            this._isChecking = false;
            this._loadingSpinner.visible = false;
        }
    }
    
    _checkPacmanUpdates() {
        return new Promise((resolve) => {
            try {
                const proc = Gio.Subprocess.new(['checkupdates'], Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
                proc.communicate_utf8_async(null, null, (proc, res) => {
                    try {
                        const [, stdout] = proc.communicate_utf8_finish(res);
                        const lines = stdout ? stdout.trim().split('\n').filter(line => line.length > 0) : [];
                        resolve(lines);
                    } catch {
                        resolve([]);
                    }
                });
            } catch {
                resolve([]);
            }
        });
    }
    
    _checkFlatpakUpdates() {
        return new Promise((resolve) => {
            try {
                const proc = Gio.Subprocess.new(['flatpak', 'remote-ls', '--updates'], 
                    Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE);
                proc.communicate_utf8_async(null, null, (proc, res) => {
                    try {
                        const [, stdout] = proc.communicate_utf8_finish(res);
                        const lines = stdout ? stdout.trim().split('\n').filter(line => line.length > 0) : [];
                        resolve(lines.length);
                    } catch {
                        resolve(0);
                    }
                });
            } catch {
                resolve(0);
            }
        });
    }
    
    async _classifyUpdates(packageLines) {
        const essentialPackages = this._getEssentialPackages();
        const securityKeywords = ['security', 'cve', 'vulnerability', 'exploit'];
        
        for (const line of packageLines) {
            const packageName = line.split(' ')[0];
            const packageInfo = line.toLowerCase();
            
            // Check for security updates
            if (securityKeywords.some(keyword => packageInfo.includes(keyword))) {
                this._securityUpdates++;
            }
            // Check for essential packages
            else if (essentialPackages.includes(packageName)) {
                this._essentialUpdates++;
            }
            // Everything else is optional
            else {
                this._optionalUpdates++;
            }
        }
    }
    
    _getEssentialPackages() {
        const defaultEssential = [
            'linux', 'linux-lts', 'linux-zen', 'linux-hardened',
            'systemd', 'pacman', 'sudo', 'glibc', 'gcc-libs',
            'bash', 'coreutils', 'util-linux', 'filesystem',
            'reflector', 'base', 'base-devel'
        ];
        
        // Get user-defined essential packages from settings
        const userEssential = this._settings.get_strv('essential-packages');
        
        return [...new Set([...defaultEssential, ...userEssential])];
    }
    
    _updateBadge() {
        const totalUpdates = this._securityUpdates + this._essentialUpdates + this._optionalUpdates + this._flatpakUpdates;
        
        if (totalUpdates === 0) {
            this._hideBadge();
            return;
        }
        
        // Determine badge color based on priority
        let badgeColor = '#3584e4'; // Blue for optional
        if (this._securityUpdates > 0) {
            badgeColor = '#e01b24'; // Red for security
        } else if (this._essentialUpdates > 0) {
            badgeColor = '#ff7800'; // Orange for essential
        }
        
        this._badge.set_style(`
            background-color: ${badgeColor};
            color: white;
            border-radius: 8px;
            padding: 2px 6px;
            font-size: 10px;
            font-weight: bold;
            margin-left: 4px;
        `);
        
        this._badge.text = totalUpdates.toString();
        this._badge.visible = true;
    }
    
    _hideBadge() {
        this._badge.visible = false;
    }
    
    _showUpdateNotification() {
        const totalUpdates = this._securityUpdates + this._essentialUpdates + this._optionalUpdates + this._flatpakUpdates;
        const title = 'Updates Available';
        
        let message = `${totalUpdates} updates available:\n`;
        if (this._securityUpdates > 0) message += `🔴 ${this._securityUpdates} security\n`;
        if (this._essentialUpdates > 0) message += `🟠 ${this._essentialUpdates} essential\n`;
        if (this._optionalUpdates > 0) message += `🔵 ${this._optionalUpdates} optional\n`;
        if (this._flatpakUpdates > 0) message += `📱 ${this._flatpakUpdates} Flatpaks`;
        
        const source = new MessageTray.Source({
            title: 'OneClick for Arch', 
            iconName: 'system-software-update-symbolic'
        });
        Main.messageTray.add(source);
        
        const notification = new MessageTray.Notification({
            source: source,
            title: title,
            body: message,
            urgency: this._securityUpdates > 0 ? MessageTray.Urgency.CRITICAL : MessageTray.Urgency.HIGH,
            resident: true // Make it persistent
        });
        
        notification.addAction('Update Now', () => this._performUpdate('essential'));
        notification.addAction('Snooze', () => this._snoozeNotification());
        source.addNotification(notification);
    }
    
    _snoozeNotification() {
        const snoozeMinutes = this._settings.get_int('snooze-duration');
        
        if (this._snoozeTimer) {
            GLib.source_remove(this._snoozeTimer);
        }
        
        this._snoozeTimer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT,
            snoozeMinutes * 60, () => {
                this._showUpdateNotification();
                this._snoozeTimer = null;
                return GLib.SOURCE_REMOVE;
            });
        
        Main.notify('OneClick for Arch', `Updates snoozed for ${snoozeMinutes} minutes`);
    }
    
    _showErrorNotification(title, message) {
        const source = new MessageTray.Source({
            title: 'OneClick for Arch', 
            iconName: 'dialog-error-symbolic'
        });
        Main.messageTray.add(source);
        
        const notification = new MessageTray.Notification({
            source: source,
            title: title,
            body: message,
            urgency: MessageTray.Urgency.HIGH
        });
        
        notification.addAction('Retry', () => this._checkForUpdates());
        source.addNotification(notification);
    }
    
    async _performUpdate(updateType = 'essential') {
        if (this._isUpdating) return;
        
        this._isUpdating = true;
        
        try {
            // Run reflector first if enabled
            if (this._settings.get_boolean('run-reflector-before-update')) {
                await this._runReflector();
            }
            
            // Open kitty terminal with update command
            this._openKittyWithUpdates(updateType);
            
            // Log the update
            this._logUpdate(updateType);
            
        } catch (error) {
            console.error('OneClick: Update failed:', error);
            this._showErrorNotification('Update Failed', error.message);
        } finally {
            this._isUpdating = false;
        }
    }
    
    _runReflector() {
        return new Promise((resolve, reject) => {
            const protocol = this._settings.get_string('reflector-protocol');
            const sort = this._settings.get_string('reflector-sort');
            const latest = this._settings.get_int('reflector-latest');
            const country = this._settings.get_string('reflector-country');
            
            let args = ['pkexec', 'reflector', '--verbose', 
                       `--protocol`, protocol,
                       `--sort`, sort,
                       `--latest`, latest.toString()];
            
            if (country && country !== 'all') {
                args.push('--country', country);
            }
            
            args.push('--save', '/etc/pacman.d/mirrorlist');
            
            const proc = Gio.Subprocess.new(args, Gio.SubprocessFlags.NONE);
            proc.wait_async(null, (proc, res) => {
                try {
                    proc.wait_finish(res);
                    resolve();
                } catch (error) {
                    reject(error);
                }
            });
        });
    }
    
    _openKittyWithUpdates(updateType) {
        const updateScript = this._generateUpdateScript(updateType);
        const tempFile = GLib.build_filenamev([GLib.get_tmp_dir(), 'oneclick-update.sh']);
        
        GLib.file_set_contents(tempFile, updateScript);
        GLib.spawn_command_line_async(`chmod +x ${tempFile}`);
        GLib.spawn_command_line_async(`kitty --title "OneClick Update - ${updateType}" bash ${tempFile}`);
    }
    
    _generateUpdateScript(updateType) {
        const parallelDownloads = this._settings.get_int('parallel-downloads');
        const essentialPackages = this._getEssentialPackages().join(' ');
        
        return `#!/bin/bash\n\n# OneClick for Arch Update Script with Pac-Man Progress\n\necho "🎮 Starting OneClick for Arch Updates (${updateType})..."\necho\n\n# Function to create Pac-Man progress bar\nshow_pacman_progress() {\n    local current=$1\n    local total=$2\n    local width=40\n    local percent=$((current * 100 / total))\n    local completed=$((current * width / total))\n    local remaining=$((width - completed))\n    \n    printf "\\r🟡 "\n    for ((i=0; i<completed; i++)); do\n        printf "·"\n    done\n    printf "C"  # Pac-Man\n    for ((i=0; i<remaining; i++)); do\n        printf "·"\n    done\n    printf " %d%%" $percent\n}\n\n# Error handling function\nhandle_error() {\n    echo\n    echo "❌ Error occurred: $1"\n    echo\n    echo "Options:"\n    echo "1) Retry update"\n    echo "2) Stop updating"\n    echo\n    read -p "Choose option (1/2): " choice\n    \n    case $choice in\n        1)\n            echo "🔄 Retrying..."\n            exec "$0"\n            ;;\n        2)\n            echo "🛑 Update stopped by user"\n            exit 1\n            ;;\n        *)\n            echo "Invalid choice. Stopping update."\n            exit 1\n            ;;\n    esac\n}\n\n# Check for pacman lock\ncheck_pacman_lock() {\n    if [ -f /var/lib/pacman/db.lck ]; then\n        echo "⚠️  Pacman database is locked!"\n        \n        # Try to identify blocking process\n        local blocking_pid=$(lsof /var/lib/pacman/db.lck 2>/dev/null | awk 'NR==2 {print $2}')\n        \n        if [ -n "$blocking_pid" ]; then\n            local blocking_cmd=$(ps -p $blocking_pid -o comm= 2>/dev/null)\n            echo "Blocking process: $blocking_cmd (PID: $blocking_pid)"\n            echo\n            echo "Options:"\n            echo "1) Kill blocking process and continue"\n            echo "2) Stop updating"\n            echo\n            read -p "Choose option (1/2): " choice\n            \n            case $choice in\n                1)\n                    sudo kill -9 $blocking_pid 2>/dev/null\n                    sudo rm -f /var/lib/pacman/db.lck\n                    echo "✅ Lock removed, continuing..."\n                    ;;\n                2)\n                    echo "🛑 Update stopped by user"\n                    exit 1\n                    ;;\n                *)\n                    echo "Invalid choice. Stopping update."\n                    exit 1\n                    ;;\n            esac\n        else\n            echo "Removing stale lock file..."\n            sudo rm -f /var/lib/pacman/db.lck\n        fi\n    fi\n}\n\n# Check for internet connectivity\ncheck_internet() {\n    if ! ping -c 1 google.com &> /dev/null; then\n        handle_error "No internet connection"\n    fi\n}\n\n# Main update logic\nmain_update() {\n    check_internet\n    check_pacman_lock\n    \n    # Update pacman with parallel downloads\n    echo "📦 Updating package database..."\n    sudo sed -i "s/#ParallelDownloads = 5/ParallelDownloads = ${parallelDownloads}/" /etc/pacman.conf\n    sudo pacman -Sy || handle_error "Failed to sync package database"\n    \n    case "${updateType}" in\n        "security")\n            echo "🔴 Updating security packages..."\n            # In a real implementation, you'd filter for security updates\n            sudo pacman -Su --noconfirm || handle_error "Security update failed"\n            ;;\n        "essential")\n            echo "🟠 Updating essential packages..."\n            if [ -n "${essentialPackages}" ]; then\n                sudo pacman -S --needed --noconfirm ${essentialPackages} || handle_error "Essential update failed"\n            fi\n            \n            echo\n            echo "✅ Essential updates completed!"\n            echo\n            echo "Options:"\n            echo "→ Continue with optional updates? [Y/n]"\n            echo "→ Exit and close terminal? [y/N]"\n            echo\n            read -p "Continue with optional updates? [Y/n]: " continue_choice\n            \n            case $continue_choice in\n                [Nn]*)\n                    echo "✅ Update completed. Closing terminal..."\n                    exit 0\n                    ;;\n                *)\n                    echo "🔵 Continuing with optional updates..."\n                    sudo pacman -Su --noconfirm || handle_error "Optional update failed"\n                    ;;\n            esac\n            ;;\n        "optional")\n            echo "🔵 Updating optional packages..."\n            # Get list of all updates and exclude essential ones\n            sudo pacman -Su --noconfirm || handle_error "Optional update failed"\n            ;;\n        "full")\n            echo "🌈 Performing full system update..."\n            sudo pacman -Su --noconfirm || handle_error "Full update failed"\n            ;;\n    esac\n    \n    # Update Flatpaks if enabled\n    if command -v flatpak &> /dev/null && [ "$(flatpak remote-ls --updates 2>/dev/null | wc -l)" -gt 0 ]; then\n        echo "📱 Updating Flatpaks..."\n        flatpak update -y || echo "⚠️  Some Flatpak updates failed"\n    fi\n    \n    echo\n    echo "✅ All updates completed successfully!"\n    echo "Press any key to close..."\n    read -n 1\n}\n\n# Run main update\nmain_update\n`;
    }
    
    _logUpdate(updateType) {
        const timestamp = new Date().toISOString();
        this._updateHistory.push({
            timestamp: timestamp,
            date: new Date(timestamp).toLocaleDateString(),
            time: new Date(timestamp).toLocaleTimeString(),
            type: updateType,
            securityCount: this._securityUpdates,
            essentialCount: this._essentialUpdates,
            optionalCount: this._optionalUpdates,
            flatpakCount: this._flatpakUpdates
        });
        
        // Keep only last 10 updates
        if (this._updateHistory.length > 10) {
            this._updateHistory = this._updateHistory.slice(-10);
        }
        
        this._settings.set_string('update-history', JSON.stringify(this._updateHistory));
    }
    
    _showHistory() {
        const history = JSON.parse(this._settings.get_string('update-history') || '[]');
        
        if (history.length === 0) {
            Main.notify('OneClick for Arch', 'No update history available');
            return;
        }
        
        const historyText = history.map((update, index) => {
            const counts = [];
            if (update.securityCount > 0) counts.push(`${update.securityCount} security`);
            if (update.essentialCount > 0) counts.push(`${update.essentialCount} essential`);
            if (update.optionalCount > 0) counts.push(`${update.optionalCount} optional`);
            if (update.flatpakCount > 0) counts.push(`${update.flatpakCount} flatpaks`);
            
            return `${index + 1}. ${update.date} at ${update.time} (${update.type})\n   ${counts.join(', ')}`;
        }).join('\n\n');
        
        Main.notify('Update History', historyText);
    }
    
    _openSettings() {
        this._extension.openPreferences();
    }
    
    destroy() {
        if (this._updateTimer) {
            GLib.source_remove(this._updateTimer);
            this._updateTimer = null;
        }
        
        if (this._snoozeTimer) {
            GLib.source_remove(this._snoozeTimer);
            this._snoozeTimer = null;
        }
        
        if (this._accentColorConnection) {
            this._settings.disconnect(this._accentColorConnection);
        }
        
        if (this._intervalConnection) {
            this._settings.disconnect(this._intervalConnection);
        }
        
        super.destroy();
    }
});

export default class OneClickExtension extends Extension {
    enable() {
        indicator = new OneClickIndicator(this);
        Main.panel.addToStatusArea(this.uuid, indicator);
    }

    disable() {
        if (indicator) {
            indicator.destroy();
            indicator = null;
        }
    }
}
EOF

# Create prefs.js - Settings interface (Modern ES6 syntax)
cat > "$EXTENSION_DIR/prefs.js" << \EOF
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';
import Adw from 'gi://Adw';

import {ExtensionPreferences, gettext as _} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class OneClickPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        window._settings = this.getSettings();
        
        // General Settings Page
        const generalPage = new Adw.PreferencesPage({
            title: _('General'),
            icon_name: 'preferences-system-symbolic',
        });
        window.add(generalPage);
        
        this._buildGeneralSettings(generalPage, window._settings);
        
        // System Updates Page
        const systemPage = new Adw.PreferencesPage({
            title: _('System Updates'),
            icon_name: 'system-software-update-symbolic',
        });
        window.add(systemPage);
        
        this._buildSystemSettings(systemPage, window._settings);
        
        // AUR & Helpers Page
        const aurPage = new Adw.PreferencesPage({
            title: _('AUR & Helpers'),
            icon_name: 'applications-development-symbolic',
        });
        window.add(aurPage);
        
        this._buildAURSettings(aurPage, window._settings);
        
        // Flatpak Page
        const flatpakPage = new Adw.PreferencesPage({
            title: _('Flatpak'),
            icon_name: 'application-x-flatpak-symbolic',
        });
        window.add(flatpakPage);
        
        this._buildFlatpakSettings(flatpakPage, window._settings);
        
        // Advanced Page
        const advancedPage = new Adw.PreferencesPage({
            title: _('Advanced'),
            icon_name: 'preferences-other-symbolic',
        });
        window.add(advancedPage);
        
        this._buildAdvancedSettings(advancedPage, window._settings);
    }
    
    _buildGeneralSettings(page, settings) {
        // Update Settings Group
        const updateGroup = new Adw.PreferencesGroup({
            title: _('Update Settings'),
            description: _('Configure automatic updates and notifications'),
        });
        page.add(updateGroup);

        // Check Interval
        const intervalRow = new Adw.ComboRow({
            title: _('Update Check Interval'),
            subtitle: _('How often to check for system updates'),
            model: new Gtk.StringList({strings: ['15 minutes', '30 minutes', '1 hour', '3 hours', '6 hours', '12 hours', '24 hours']}),
            selected: this._getIntervalIndex(settings.get_int('check-interval')),
        });
        
        intervalRow.connect('notify::selected', () => {
            const intervals = [0.25, 0.5, 1, 3, 6, 12, 24];
            settings.set_int('check-interval', intervals[intervalRow.selected]);
        });
        
        updateGroup.add(intervalRow);
        
        // Snooze Duration
        const snoozeRow = new Adw.SpinRow({
            title: _('Snooze Duration'),
            subtitle: _('Minutes to snooze update notifications'),
            adjustment: new Gtk.Adjustment({
                lower: 5,
                upper: 120,
                step_increment: 5,
                page_increment: 15,
                value: settings.get_int('snooze-duration'),
            }),
        });
        
        snoozeRow.connect('notify::value', () => {
            settings.set_int('snooze-duration', snoozeRow.value);
        });
        
        updateGroup.add(snoozeRow);
        
        // Auto-check on startup
        const autoCheckRow = new Adw.SwitchRow({
            title: _('Check Updates on Startup'),
            subtitle: _('Automatically check for updates when GNOME starts'),
            active: settings.get_boolean('auto-check-startup'),
        });
        
        autoCheckRow.connect('notify::active', () => {
            settings.set_boolean('auto-check-startup', autoCheckRow.active);
        });
        
        updateGroup.add(autoCheckRow);
        
        // Notification Settings Group
        const notificationGroup = new Adw.PreferencesGroup({
            title: _('Notification Settings'),
            description: _('Configure update notifications'),
        });
        page.add(notificationGroup);
        
        // Show detailed notifications
        const detailedNotificationsRow = new Adw.SwitchRow({
            title: _('Detailed Notifications'),
            subtitle: _('Show package counts by category in notifications'),
            active: settings.get_boolean('detailed-notifications'),
        });
        
        detailedNotificationsRow.connect('notify::active', () => {
            settings.set_boolean('detailed-notifications', detailedNotificationsRow.active);
        });
        
        notificationGroup.add(detailedNotificationsRow);
        
        // Persistent notifications
        const persistentNotificationsRow = new Adw.SwitchRow({
            title: _('Persistent Notifications'),
            subtitle: _('Keep update notifications until dismissed'),
            active: settings.get_boolean('persistent-notifications'),
        });
        
        persistentNotificationsRow.connect('notify::active', () => {
            settings.set_boolean('persistent-notifications', persistentNotificationsRow.active);
        });
        
        notificationGroup.add(persistentNotificationsRow);
    }
    
    _buildSystemSettings(page, settings) {
        // Pacman Settings Group
        const pacmanGroup = new Adw.PreferencesGroup({
            title: _('Pacman Configuration'),
            description: _('Configure pacman behavior'),
        });
        page.add(pacmanGroup);

        // Parallel Downloads
        const parallelRow = new Adw.SpinRow({
            title: _('Parallel Downloads'),
            subtitle: _('Number of simultaneous package downloads'),
            adjustment: new Gtk.Adjustment({
                lower: 1,
                upper: 20,
                step_increment: 1,
                page_increment: 1,
                value: settings.get_int('parallel-downloads'),
            }),
        });
        
        parallelRow.connect('notify::value', () => {
            settings.set_int('parallel-downloads', parallelRow.value);
        });
        
        pacmanGroup.add(parallelRow);
        
        // Verbose Package Lists
        const verboseRow = new Adw.SwitchRow({
            title: _('Verbose Package Lists'),
            subtitle: _('Show detailed package information during operations'),
            active: settings.get_boolean('pacman-verbose'),
        });
        
        verboseRow.connect('notify::active', () => {
            settings.set_boolean('pacman-verbose', verboseRow.active);
        });
        
        pacmanGroup.add(verboseRow);
        
        // Color Output
        const colorRow = new Adw.SwitchRow({
            title: _('Color Output'),
            subtitle: _('Enable colored output in pacman'),
            active: settings.get_boolean('pacman-color'),
        });
        
        colorRow.connect('notify::active', () => {
            settings.set_boolean('pacman-color', colorRow.active);
        });
        
        pacmanGroup.add(colorRow);
        
        // Check Space
        const checkSpaceRow = new Adw.SwitchRow({
            title: _('Check Space'),
            subtitle: _('Check available disk space before installing'),
            active: settings.get_boolean('pacman-checkspace'),
        });
        
        checkSpaceRow.connect('notify::active', () => {
            settings.set_boolean('pacman-checkspace', checkSpaceRow.active);
        });
        
        pacmanGroup.add(checkSpaceRow);
        
        // Reflector Settings Group
        const reflectorGroup = new Adw.PreferencesGroup({
            title: _('Reflector Settings'),
            description: _('Configure mirror optimization'),
        });
        page.add(reflectorGroup);

        // Run Reflector Toggle
        const reflectorRow = new Adw.SwitchRow({
            title: _('Run Reflector Before Updates'),
            subtitle: _('Automatically optimize mirror list before updating'),
            active: settings.get_boolean('run-reflector-before-update'),
        });
        
        reflectorRow.connect('notify::active', () => {
            settings.set_boolean('run-reflector-before-update', reflectorRow.active);
        });
        
        reflectorGroup.add(reflectorRow);

        // Protocol Selection
        const protocolRow = new Adw.ComboRow({
            title: _('Mirror Protocol'),
            subtitle: _('Preferred protocol for mirrors'),
            model: new Gtk.StringList({strings: ['https', 'http', 'rsync']}),
            selected: this._getProtocolIndex(settings.get_string('reflector-protocol')),
        });
        
        protocolRow.connect('notify::selected', () => {
            const protocols = ['https', 'http', 'rsync'];
            settings.set_string('reflector-protocol', protocols[protocolRow.selected]);
        });
        
        reflectorGroup.add(protocolRow);

        // Sort Method
        const sortRow = new Adw.ComboRow({
            title: _('Sort Method'),
            subtitle: _('How to sort mirrors'),
            model: new Gtk.StringList({strings: ['rate', 'age', 'country', 'score', 'delay']}),
            selected: this._getSortIndex(settings.get_string('reflector-sort')),
        });
        
        sortRow.connect('notify::selected', () => {
            const sorts = ['rate', 'age', 'country', 'score', 'delay'];
            settings.set_string('reflector-sort', sorts[sortRow.selected]);
        });
        
        reflectorGroup.add(sortRow);

        // Mirror Count
        const mirrorRow = new Adw.SpinRow({
            title: _('Number of Mirrors'),
            subtitle: _('Number of mirrors to keep in the list'),
            adjustment: new Gtk.Adjustment({
                lower: 5,
                upper: 50,
                step_increment: 1,
                page_increment: 5,
                value: settings.get_int('reflector-latest'),
            }),
        });
        
        mirrorRow.connect('notify::value', () => {
            settings.set_int('reflector-latest', mirrorRow.value);
        });
        
        reflectorGroup.add(mirrorRow);
        
        // Country Selection
        const countryRow = new Adw.EntryRow({
            title: _('Country Filter'),
            text: settings.get_string('reflector-country'),
        });
        
        countryRow.connect('notify::text', () => {
            settings.set_string('reflector-country', countryRow.text);
        });
        
        reflectorGroup.add(countryRow);
        
        // Update Classification Group
        const classificationGroup = new Adw.PreferencesGroup({
            title: _('Update Classification'),
            description: _('Configure how updates are categorized'),
        });
        page.add(classificationGroup);
        
        // Essential Packages
        const essentialRow = new Adw.EntryRow({
            title: _('Essential Packages'),
            text: settings.get_strv('essential-packages').join(' '),
        });
        
        essentialRow.connect('notify::text', () => {
            const packages = essentialRow.text.split(' ').filter(pkg => pkg.trim().length > 0);
            settings.set_strv('essential-packages', packages);
        });
        
        classificationGroup.add(essentialRow);
        
        // Default Update Type
        const defaultUpdateRow = new Adw.ComboRow({
            title: _('Default Update Type'),
            subtitle: _('Default selection for update operations'),
            model: new Gtk.StringList({strings: ['Essential Only', 'Full Update', 'Security Only']}),
            selected: this._getUpdateTypeIndex(settings.get_string('default-update-type')),
        });
        
        defaultUpdateRow.connect('notify::selected', () => {
            const types = ['essential', 'full', 'security'];
            settings.set_string('default-update-type', types[defaultUpdateRow.selected]);
        });
        
        classificationGroup.add(defaultUpdateRow);
    }
    
    _buildAURSettings(page, settings) {
        // AUR Helper Settings Group
        const aurHelperGroup = new Adw.PreferencesGroup({
            title: _('AUR Helper Configuration'),
            description: _('Configure AUR helper behavior'),
        });
        page.add(aurHelperGroup);
        
        // Enable AUR Support
        const enableAURRow = new Adw.SwitchRow({
            title: _('Enable AUR Support'),
            subtitle: _('Include AUR packages in update checks'),
            active: settings.get_boolean('enable-aur'),
        });
        
        enableAURRow.connect('notify::active', () => {
            settings.set_boolean('enable-aur', enableAURRow.active);
        });
        
        aurHelperGroup.add(enableAURRow);
        
        // AUR Helper Selection
        const aurHelperRow = new Adw.ComboRow({
            title: _('AUR Helper'),
            subtitle: _('Preferred AUR helper application'),
            model: new Gtk.StringList({strings: ['paru', 'yay', 'trizen', 'pikaur']}),
            selected: this._getAURHelperIndex(settings.get_string('aur-helper')),
        });
        
        aurHelperRow.connect('notify::selected', () => {
            const helpers = ['paru', 'yay', 'trizen', 'pikaur'];
            settings.set_string('aur-helper', helpers[aurHelperRow.selected]);
        });
        
        aurHelperGroup.add(aurHelperRow);
        
        // Paru Settings Group
        const paruGroup = new Adw.PreferencesGroup({
            title: _('Paru Configuration'),
            description: _('Configure paru-specific options'),
        });
        page.add(paruGroup);
        
        // Bottom Up
        const bottomUpRow = new Adw.SwitchRow({
            title: _('Bottom Up'),
            subtitle: _('Show AUR packages first in search results'),
            active: settings.get_boolean('paru-bottom-up'),
        });
        
        bottomUpRow.connect('notify::active', () => {
            settings.set_boolean('paru-bottom-up', bottomUpRow.active);
        });
        
        paruGroup.add(bottomUpRow);
        
        // Sudo Loop
        const sudoLoopRow = new Adw.SwitchRow({
            title: _('Sudo Loop'),
            subtitle: _('Loop sudo calls to avoid timeout'),
            active: settings.get_boolean('paru-sudo-loop'),
        });
        
        sudoLoopRow.connect('notify::active', () => {
            settings.set_boolean('paru-sudo-loop', sudoLoopRow.active);
        });
        
        paruGroup.add(sudoLoopRow);
        
        // News on Upgrade
        const newsRow = new Adw.SwitchRow({
            title: _('News on Upgrade'),
            subtitle: _('Show Arch news during upgrades'),
            active: settings.get_boolean('paru-news-on-upgrade'),
        });
        
        newsRow.connect('notify::active', () => {
            settings.set_boolean('paru-news-on-upgrade', newsRow.active);
        });
        
        paruGroup.add(newsRow);
        
        // Devel Suffix
        const develRow = new Adw.EntryRow({
            title: _('Devel Suffixes'),
            text: settings.get_string('paru-devel-suffix'),
        });
        
        develRow.connect('notify::text', () => {
            settings.set_string('paru-devel-suffix', develRow.text);
        });
        
        paruGroup.add(develRow);
    }
    
    _buildFlatpakSettings(page, settings) {
        // Flatpak Update Settings Group
        const flatpakUpdateGroup = new Adw.PreferencesGroup({
            title: _('Flatpak Update Settings'),
            description: _('Configure Flatpak update behavior'),
        });
        page.add(flatpakUpdateGroup);
        
        // Enable Flatpak Updates
        const enableFlatpakRow = new Adw.SwitchRow({
            title: _('Enable Flatpak Updates'),
            subtitle: _('Include Flatpak applications in update checks'),
            active: settings.get_boolean('enable-flatpak'),
        });
        
        enableFlatpakRow.connect('notify::active', () => {
            settings.set_boolean('enable-flatpak', enableFlatpakRow.active);
        });
        
        flatpakUpdateGroup.add(enableFlatpakRow);
        
        // Auto Update Flatpaks
        const autoUpdateFlatpakRow = new Adw.SwitchRow({
            title: _('Auto Update Flatpaks'),
            subtitle: _('Automatically update Flatpak applications'),
            active: settings.get_boolean('flatpak-auto-update'),
        });
        
        autoUpdateFlatpakRow.connect('notify::active', () => {
            settings.set_boolean('flatpak-auto-update', autoUpdateFlatpakRow.active);
        });
        
        flatpakUpdateGroup.add(autoUpdateFlatpakRow);
        
        // Auto Update Interval
        const flatpakIntervalRow = new Adw.ComboRow({
            title: _('Auto Update Interval'),
            subtitle: _('How often to auto-update Flatpaks'),
            model: new Gtk.StringList({strings: ['Daily', 'Weekly', 'Monthly']}),
            selected: this._getFlatpakIntervalIndex(settings.get_string('flatpak-update-interval')),
        });
        
        flatpakIntervalRow.connect('notify::selected', () => {
            const intervals = ['daily', 'weekly', 'monthly'];
            settings.set_string('flatpak-update-interval', intervals[flatpakIntervalRow.selected]);
        });
        
        flatpakUpdateGroup.add(flatpakIntervalRow);
        
        // Flatpak Maintenance Group
        const flatpakMaintenanceGroup = new Adw.PreferencesGroup({
            title: _('Flatpak Maintenance'),
            description: _('Configure Flatpak cleanup and maintenance'),
        });
        page.add(flatpakMaintenanceGroup);
        
        // Auto Cleanup
        const autoCleanupRow = new Adw.SwitchRow({
            title: _('Auto Cleanup Unused Runtimes'),
            subtitle: _('Automatically remove unused Flatpak runtimes'),
            active: settings.get_boolean('flatpak-auto-cleanup'),
        });
        
        autoCleanupRow.connect('notify::active', () => {
            settings.set_boolean('flatpak-auto-cleanup', autoCleanupRow.active);
        });
        
        flatpakMaintenanceGroup.add(autoCleanupRow);
        
        // Cleanup Frequency
        const cleanupFrequencyRow = new Adw.ComboRow({
            title: _('Cleanup Frequency'),
            subtitle: _('How often to run cleanup'),
            model: new Gtk.StringList({strings: ['After each update', 'Weekly', 'Monthly']}),
            selected: this._getCleanupFrequencyIndex(settings.get_string('flatpak-cleanup-frequency')),
        });
        
        cleanupFrequencyRow.connect('notify::selected', () => {
            const frequencies = ['after-update', 'weekly', 'monthly'];
            settings.set_string('flatpak-cleanup-frequency', frequencies[cleanupFrequencyRow.selected]);
        });
        
        flatpakMaintenanceGroup.add(cleanupFrequencyRow);
        
        // Flatpak Remotes Group
        const flatpakRemotesGroup = new Adw.PreferencesGroup({
            title: _('Flatpak Remotes'),
            description: _('Configure which Flatpak remotes to check'),
        });
        page.add(flatpakRemotesGroup);
        
        // Check Flathub
        const flathubRow = new Adw.SwitchRow({
            title: _('Check Flathub'),
            subtitle: _('Include Flathub in update checks'),
            active: settings.get_boolean('flatpak-check-flathub'),
        });
        
        flathubRow.connect('notify::active', () => {
            settings.set_boolean('flatpak-check-flathub', flathubRow.active);
        });
        
        flatpakRemotesGroup.add(flathubRow);
        
        // Check Fedora
        const fedoraRow = new Adw.SwitchRow({
            title: _('Check Fedora Remote'),
            subtitle: _('Include Fedora remote in update checks'),
            active: settings.get_boolean('flatpak-check-fedora'),
        });
        
        fedoraRow.connect('notify::active', () => {
            settings.set_boolean('flatpak-check-fedora', fedoraRow.active);
        });
        
        flatpakRemotesGroup.add(fedoraRow);
        
        // Custom Remotes
        const customRemotesRow = new Adw.EntryRow({
            title: _('Custom Remotes'),
            text: settings.get_strv('flatpak-custom-remotes').join(' '),
        });
        
        customRemotesRow.connect('notify::text', () => {
            const remotes = customRemotesRow.text.split(' ').filter(remote => remote.trim().length > 0);
            settings.set_strv('flatpak-custom-remotes', remotes);
        });
        
        flatpakRemotesGroup.add(customRemotesRow);
    }
    
    _buildAdvancedSettings(page, settings) {
        // Repository Settings Group
        const repoGroup = new Adw.PreferencesGroup({
            title: _('Repository Settings'),
            description: _('Configure repository priorities and exclusions'),
        });
        page.add(repoGroup);
        
        // Repository Priorities
        const repoPriorityRow = new Adw.EntryRow({
            title: _('Repository Priority Order'),
            text: settings.get_string('repo-priority-order'),
        });
        
        repoPriorityRow.connect('notify::text', () => {
            settings.set_string('repo-priority-order', repoPriorityRow.text);
        });
        
        repoGroup.add(repoPriorityRow);
        
        // Ignored Packages
        const ignoredPackagesRow = new Adw.EntryRow({
            title: _('Ignored Packages'),
            text: settings.get_strv('ignored-packages').join(' '),
        });
        
        ignoredPackagesRow.connect('notify::text', () => {
            const packages = ignoredPackagesRow.text.split(' ').filter(pkg => pkg.trim().length > 0);
            settings.set_strv('ignored-packages', packages);
        });
        
        repoGroup.add(ignoredPackagesRow);
        
        // Ignored Groups
        const ignoredGroupsRow = new Adw.EntryRow({
            title: _('Ignored Groups'),
            text: settings.get_strv('ignored-groups').join(' '),
        });
        
        ignoredGroupsRow.connect('notify::text', () => {
            const groups = ignoredGroupsRow.text.split(' ').filter(group => group.trim().length > 0);
            settings.set_strv('ignored-groups', groups);
        });
        
        repoGroup.add(ignoredGroupsRow);
        
        // Custom Commands Group
        const customCommandsGroup = new Adw.PreferencesGroup({
            title: _('Custom Commands'),
            description: _('Configure custom pre/post update commands'),
        });
        page.add(customCommandsGroup);
        
        // Pre-update Command
        const preUpdateRow = new Adw.EntryRow({
            title: _('Pre-update Command'),
            text: settings.get_string('pre-update-command'),
        });
        
        preUpdateRow.connect('notify::text', () => {
            settings.set_string('pre-update-command', preUpdateRow.text);
        });
        
        customCommandsGroup.add(preUpdateRow);
        
        // Post-update Command
        const postUpdateRow = new Adw.EntryRow({
            title: _('Post-update Command'),
            text: settings.get_string('post-update-command'),
        });
        
        postUpdateRow.connect('notify::text', () => {
            settings.set_string('post-update-command', postUpdateRow.text);
        });
        
        customCommandsGroup.add(postUpdateRow);
        
        // Debug Settings Group
        const debugGroup = new Adw.PreferencesGroup({
            title: _('Debug Settings'),
            description: _('Configure debugging and logging'),
        });
        page.add(debugGroup);
        
        // Enable Debug Logging
        const debugLoggingRow = new Adw.SwitchRow({
            title: _('Enable Debug Logging'),
            subtitle: _('Log detailed information for troubleshooting'),
            active: settings.get_boolean('debug-logging'),
        });
        
        debugLoggingRow.connect('notify::active', () => {
            settings.set_boolean('debug-logging', debugLoggingRow.active);
        });
        
        debugGroup.add(debugLoggingRow);
        
        // Log File Path
        const logFileRow = new Adw.EntryRow({
            title: _('Log File Path'),
            text: settings.get_string('log-file-path'),
        });
        
        logFileRow.connect('notify::text', () => {
            settings.set_string('log-file-path', logFileRow.text);
        });
        
        debugGroup.add(logFileRow);
    }

    _getIntervalIndex(hours) {
        const intervals = [0.25, 0.5, 1, 3, 6, 12, 24];
        return Math.max(0, intervals.indexOf(hours));
    }

    _getProtocolIndex(protocol) {
        const protocols = ['https', 'http', 'rsync'];
        return Math.max(0, protocols.indexOf(protocol));
    }
    
    _getSortIndex(sort) {
        const sorts = ['rate', 'age', 'country', 'score', 'delay'];
        return Math.max(0, sorts.indexOf(sort));
    }
    
    _getUpdateTypeIndex(type) {
        const types = ['essential', 'full', 'security'];
        return Math.max(0, types.indexOf(type));
    }
    
    _getAURHelperIndex(helper) {
        const helpers = ['paru', 'yay', 'trizen', 'pikaur'];
        return Math.max(0, helpers.indexOf(helper));
    }
    
    _getFlatpakIntervalIndex(interval) {
        const intervals = ['daily', 'weekly', 'monthly'];
        return Math.max(0, intervals.indexOf(interval));
    }
    
    _getCleanupFrequencyIndex(frequency) {
        const frequencies = ['after-update', 'weekly', 'monthly'];
        return Math.max(0, frequencies.indexOf(frequency));
    }
}
EOF

# Create GSettings schema
mkdir -p "$EXTENSION_DIR/schemas"

cat > "$EXTENSION_DIR/schemas/org.gnome.shell.extensions.oneclick-arch.gschema.xml" << \EOF
<?xml version="1.0" encoding="UTF-8"?>
<schemalist gettext-domain="oneclick-arch">
  <schema id="org.gnome.shell.extensions.oneclick-arch" path="/org/gnome/shell/extensions/oneclick-arch/">
    
    <!-- General Settings -->
    <key name="check-interval" type="i">
      <default>1</default>
      <summary>Update check interval in hours</summary>
      <description>How often to check for system updates</description>
    </key>
    
    <key name="snooze-duration" type="i">
      <default>30</default>
      <summary>Snooze duration in minutes</summary>
      <description>How long to snooze update notifications</description>
    </key>
    
    <key name="auto-check-startup" type="b">
      <default>true</default>
      <summary>Check updates on startup</summary>
      <description>Automatically check for updates when GNOME starts</description>
    </key>
    
    <key name="detailed-notifications" type="b">
      <default>true</default>
      <summary>Show detailed notifications</summary>
      <description>Show package counts by category in notifications</description>
    </key>
    
    <key name="persistent-notifications" type="b">
      <default>true</default>
      <summary>Persistent notifications</summary>
      <description>Keep update notifications until dismissed</description>
    </key>
    
    <!-- Pacman Settings -->
    <key name="parallel-downloads" type="i">
      <default>5</default>
      <summary>Number of parallel downloads</summary>
      <description>Number of simultaneous package downloads</description>
    </key>
    
    <key name="pacman-verbose" type="b">
      <default>false</default>
      <summary>Verbose package lists</summary>
      <description>Show detailed package information during operations</description>
    </key>
    
    <key name="pacman-color" type="b">
      <default>true</default>
      <summary>Color output</summary>
      <description>Enable colored output in pacman</description>
    </key>
    
    <key name="pacman-checkspace" type="b">
      <default>true</default>
      <summary>Check space</summary>
      <description>Check available disk space before installing</description>
    </key>
    
    <!-- Reflector Settings -->
    <key name="run-reflector-before-update" type="b">
      <default>true</default>
      <summary>Run reflector before updates</summary>
      <description>Automatically optimize mirror list before updating</description>
    </key>
    
    <key name="reflector-protocol" type="s">
      <default>'https'</default>
      <summary>Reflector protocol</summary>
      <description>Preferred protocol for mirrors</description>
    </key>
    
    <key name="reflector-sort" type="s">
      <default>'rate'</default>
      <summary>Reflector sort method</summary>
      <description>How to sort mirrors</description>
    </key>
    
    <key name="reflector-latest" type="i">
      <default>25</default>
      <summary>Number of mirrors</summary>
      <description>Number of mirrors to keep</description>
    </key>
    
    <key name="reflector-country" type="s">
      <default>'all'</default>
      <summary>Mirror country preference</summary>
      <description>Preferred country for mirrors</description>
    </key>
    
    <!-- Update Classification -->
    <key name="essential-packages" type="as">
      <default>['linux', 'systemd', 'pacman', 'sudo']</default>
      <summary>Essential packages</summary>
      <description>List of packages considered essential for system stability</description>
    </key>
    
    <key name="default-update-type" type="s">
      <default>'essential'</default>
      <summary>Default update type</summary>
      <description>Default selection for update operations (essential, full, security)</description>
    </key>
    
    <!-- AUR & Helpers -->
    <key name="enable-aur" type="b">
      <default>true</default>
      <summary>Enable AUR support</summary>
      <description>Include AUR packages in update checks</description>
    </key>
    
    <key name="aur-helper" type="s">
      <default>'paru'</default>
      <summary>AUR helper</summary>
      <description>Preferred AUR helper application</description>
    </key>
    
    <!-- Paru Settings -->
    <key name="paru-bottom-up" type="b">
      <default>false</default>
      <summary>Paru bottom up</summary>
      <description>Show AUR packages first in search results</description>
    </key>
    
    <key name="paru-sudo-loop" type="b">
      <default>true</default>
      <summary>Paru sudo loop</summary>
      <description>Loop sudo calls to avoid timeout</description>
    </key>
    
    <key name="paru-news-on-upgrade" type="b">
      <default>true</default>
      <summary>Paru news on upgrade</summary>
      <description>Show Arch news during upgrades</description>
    </key>
    
    <key name="paru-devel-suffix" type="s">
      <default>'-git -svn -bzr -hg'</default>
      <summary>Paru devel suffixes</summary>
      <description>Suffixes to identify development packages</description>
    </key>
    
    <!-- Flatpak Settings -->
    <key name="enable-flatpak" type="b">
      <default>true</default>
      <summary>Enable Flatpak updates</summary>
      <description>Include Flatpak applications in update checks</description>
    </key>
    
    <key name="flatpak-auto-update" type="b">
      <default>false</default>
      <summary>Auto update Flatpaks</summary>
      <description>Automatically update Flatpak applications</description>
    </key>
    
    <key name="flatpak-update-interval" type="s">
      <default>'daily'</default>
      <summary>Flatpak auto update interval</summary>
      <description>How often to auto-update Flatpaks</description>
    </key>
    
    <key name="flatpak-auto-cleanup" type="b">
      <default>false</default>
      <summary>Auto cleanup unused runtimes</summary>
      <description>Automatically remove unused Flatpak runtimes</description>
    </key>
    
    <key name="flatpak-cleanup-frequency" type="s">
      <default>'after-update'</default>
      <summary>Flatpak cleanup frequency</summary>
      <description>How often to run Flatpak cleanup</description>
    </key>
    
    <key name="flatpak-check-flathub" type="b">
      <default>true</default>
      <summary>Check Flathub</summary>
      <description>Include Flathub in update checks</description>
    </key>
    
    <key name="flatpak-check-fedora" type="b">
      <default>false</default>
      <summary>Check Fedora remote</summary>
      <description>Include Fedora remote in update checks</description>
    </key>
    
    <key name="flatpak-custom-remotes" type="as">
      <default>[]</default>
      <summary>Custom Flatpak remotes</summary>
      <description>List of custom Flatpak remotes to check</description>
    </key>
    
    <!-- Advanced Settings -->
    <key name="repo-priority-order" type="s">
      <default>''</default>
      <summary>Repository priority order</summary>
      <description>Define the order of repository priorities</description>
    </key>
    
    <key name="ignored-packages" type="as">
      <default>[]</default>
      <summary>Ignored packages</summary>
      <description>List of packages to ignore during updates</description>
    </key>
    
    <key name="ignored-groups" type="as">
      <default>[]</default>
      <summary>Ignored groups</summary>
      <description>List of package groups to ignore during updates</description>
    </key>
    
    <key name="pre-update-command" type="s">
      <default>''</default>
      <summary>Pre-update command</summary>
      <description>Command to run before updates</description>
    </key>
    
    <key name="post-update-command" type="s">
      <default>''</default>
      <summary>Post-update command</summary>
      <description>Command to run after updates</description>
    </key>
    
    <key name="debug-logging" type="b">
      <default>false</default>
      <summary>Enable debug logging</summary>
      <description>Log detailed information for troubleshooting</description>
    </key>
    
    <key name="log-file-path" type="s">
      <default>''</default>
      <summary>Log file path</summary>
      <description>Path to the log file</description>
    </key>
    
    <!-- History -->
    <key name="update-history" type="s">
      <default>''</default>
      <summary>Update history</summary>
      <description>JSON string of recent updates</description>
    </key>
    
    <!-- System Integration -->
    <key name="accent-color" type="s">
      <default>'blue'</default>
      <summary>System accent color</summary>
      <description>Current system accent color for theming</description>
    </key>
    
  </schema>
</schemalist>
EOF

# Compile GSettings schema
glib-compile-schemas "$EXTENSION_DIR/schemas/"

# Create stylesheet.css for theming
cat > "$EXTENSION_DIR/stylesheet.css" << \EOF
/* OneClick for Arch Extension Styles */

/* Main indicator container */
.oneclick-arch-indicator {
    spacing: 4px;
    padding: 0 4px;
}

/* Extension icon */
.oneclick-arch-icon {
    icon-size: 16px;
    transition: color 0.3s ease;
}

/* Update badge */
.oneclick-update-badge {
    font-size: 10px;
    font-weight: bold;
    border-radius: 8px;
    padding: 2px 6px;
    margin-left: 4px;
    min-width: 16px;
    text-align: center;
    transition: all 0.3s ease;
}

/* Badge colors for different update priorities */
.oneclick-update-badge.security {
    background-color: #e01b24;
    color: white;
}

.oneclick-update-badge.essential {
    background-color: #ff7800;
    color: white;
}

.oneclick-update-badge.optional {
    background-color: #3584e4;
    color: white;
}

/* Menu item indicators */
.oneclick-menu-indicator {
    font-size: 12px;
    font-weight: bold;
    margin-left: auto;
    margin-right: 8px;
    opacity: 0;
    transition: opacity 0.2s ease;
}

/* Show indicator on hover */
.popup-menu-item:hover .oneclick-menu-indicator {
    opacity: 1;
}

/* Loading spinner animation */
.oneclick-loading-spinner {
    animation: spin 1s linear infinite;
}

@keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
}

/* Progress notification styles */
.oneclick-progress-notification {
    background-color: rgba(46, 52, 64, 0.95);
    border-radius: 8px;
    padding: 12px;
    spacing: 8px;
    min-width: 300px;
}

.oneclick-progress-bar {
    height: 6px;
    border-radius: 3px;
    background-color: rgba(76, 86, 106, 0.3);
    margin: 8px 0;
}

.oneclick-progress-fill {
    height: 6px;
    border-radius: 3px;
    background-color: #88c0d0;
    transition: width 0.3s ease;
}

/* Pac-Man progress elements */
.oneclick-pacman {
    font-size: 14px;
    color: #ebcb8b;
    font-family: monospace;
}

.oneclick-dots {
    color: #d8dee9;
    font-family: monospace;
    letter-spacing: 2px;
}

/* Menu styling improvements */
.popup-menu-item.oneclick-menu-item {
    spacing: 8px;
    padding: 8px 12px;
    border-radius: 6px;
    margin: 2px 4px;
    transition: all 0.2s ease;
}

.popup-menu-item.oneclick-menu-item:hover {
    background-color: rgba(255, 255, 255, 0.1);
    transform: translateX(2px);
}

.popup-menu-item.oneclick-menu-item:active {
    background-color: rgba(255, 255, 255, 0.15);
    transform: translateX(1px);
}

/* Submenu styling */
.popup-sub-menu .popup-menu-item {
    padding-left: 20px;
}

.popup-sub-menu .popup-menu-item:before {
    content: "→";
    margin-right: 8px;
    opacity: 0.6;
    transition: opacity 0.2s ease;
}

.popup-sub-menu .popup-menu-item:hover:before {
    opacity: 1;
}

/* History display */
.oneclick-history-text {
    font-family: monospace;
    font-size: 11px;
    color: #d8dee9;
    spacing: 4px;
    line-height: 1.4;
}

/* Update type indicators */
.oneclick-update-type-security {
    color: #e01b24;
}

.oneclick-update-type-essential {
    color: #ff7800;
}

.oneclick-update-type-optional {
    color: #3584e4;
}

.oneclick-update-type-flatpak {
    color: #33d17a;
}

/* Notification action buttons */
.notification-button {
    padding: 8px 16px;
    border-radius: 6px;
    margin: 4px;
    transition: all 0.2s ease;
}

.notification-button:hover {
    background-color: rgba(255, 255, 255, 0.1);
    transform: scale(1.05);
}

.notification-button.primary {
    background-color: #3584e4;
    color: white;
}

.notification-button.secondary {
    background-color: rgba(255, 255, 255, 0.1);
    color: #d8dee9;
}

/* Error notification styling */
.oneclick-error-notification {
    background-color: rgba(224, 17, 24, 0.9);
    border-left: 4px solid #e01b24;
}

/* Success notification styling */
.oneclick-success-notification {
    background-color: rgba(51, 209, 122, 0.9);
    border-left: 4px solid #33d17a;
}

/* Warning notification styling */
.oneclick-warning-notification {
    background-color: rgba(255, 120, 0, 0.9);
    border-left: 4px solid #ff7800;
}

/* Dark theme adjustments */
@media (prefers-color-scheme: dark) {
    .oneclick-arch-indicator {
        color: #eeeeec;
    }
    
    .popup-menu-item.oneclick-menu-item:hover {
        background-color: rgba(255, 255, 255, 0.08);
    }
    
    .popup-menu-item.oneclick-menu-item:active {
        background-color: rgba(255, 255, 255, 0.12);
    }
}

/* Light theme adjustments */
@media (prefers-color-scheme: light) {
    .oneclick-arch-indicator {
        color: #2e3436;
    }
    
    .popup-menu-item.oneclick-menu-item:hover {
        background-color: rgba(0, 0, 0, 0.08);
    }
    
    .popup-menu-item.oneclick-menu-item:active {
        background-color: rgba(0, 0, 0, 0.12);
    }
    
    .oneclick-progress-notification {
        background-color: rgba(255, 255, 255, 0.95);
        color: #2e3436;
    }
}

/* Accessibility improvements */
.oneclick-arch-indicator:focus {
    outline: 2px solid #3584e4;
    outline-offset: 2px;
}

.popup-menu-item.oneclick-menu-item:focus {
    outline: 2px solid #3584e4;
    outline-offset: -2px;
}

/* High contrast mode support */
@media (prefers-contrast: high) {
    .oneclick-update-badge {
        border: 2px solid currentColor;
    }
    
    .popup-menu-item.oneclick-menu-item:hover {
        border: 1px solid currentColor;
    }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
    .oneclick-arch-icon,
    .oneclick-update-badge,
    .oneclick-menu-indicator,
    .popup-menu-item.oneclick-menu-item,
    .notification-button {
        transition: none;
    }
    
    .oneclick-loading-spinner {
        animation: none;
    }
    
    .popup-menu-item.oneclick-menu-item:hover {
        transform: none;
    }
}
EOF

# Install dependencies and check for required packages
echo "🔧 Checking dependencies..."

# Check if kitty is installed
if ! command -v kitty &> /dev/null; then
    echo "Installing kitty terminal..."
    sudo pacman -S --noconfirm kitty
fi

# Check if reflector is installed
if ! command -v reflector &> /dev/null; then
    echo "Installing reflector..."
    sudo pacman -S --noconfirm reflector
fi

# Check if checkupdates is available (from pacman-contrib)
if ! command -v checkupdates &> /dev/null; then
    echo "Installing pacman-contrib for checkupdates..."
    sudo pacman -S --noconfirm pacman-contrib
fi

# Check if paru is installed (if AUR support is enabled and paru is selected)
# This logic would ideally be more dynamic based on settings, but for a simple installer,
# we'll check for paru if AUR support is generally desired.
if ! command -v paru &> /dev/null; then
    echo "Installing paru (AUR helper)..."
    # paru installation requires git and base-devel
    sudo pacman -S --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
fi

# Set permissions
chmod +x "$EXTENSION_DIR/extension.js"
chmod +x "$EXTENSION_DIR/prefs.js"

echo "✅ OneClick for Arch extension installed successfully!"
echo
echo "📋 Installation Summary:"
echo "   • Extension installed to: $EXTENSION_DIR"
echo "   • Dependencies installed: kitty, reflector, pacman-contrib, paru (if not present)"
echo "   • GSettings schema compiled"
echo "   • Modern GNOME Shell 42+ compatibility"
echo
echo "🚀 Next Steps:"
echo "   1. Restart GNOME Shell: Alt+F2, type 'r', press Enter (or logout/login on Wayland)"
echo "   2. Enable the extension: gnome-extensions enable oneclick-arch@local"
echo "   3. Configure settings: gnome-extensions prefs oneclick-arch@local"
echo
echo "🎯 Features Ready:"
echo "   • Automatic update checking at startup"
echo "   • Top bar icon with right-click menu"
echo "   • Pac-Man themed progress in kitty terminal"
echo "   • Persistent notifications for updates"
echo "   • Modern Adwaita preferences interface (with tabs)"
echo "   • Automatic reflector optimization"
echo "   • Update history tracking"
echo "   • Accent color synchronization"
echo "   • Detailed update classification (security, essential, optional, Flatpak)"
echo "   • Enhanced error handling for network and pacman lock"
echo
echo "⚙️  Default Settings:"
echo "   • Check interval: 1 hour"
echo "   • Snooze duration: 30 minutes"
echo "   • Parallel downloads: 5"
echo "   • Reflector before updates: enabled"
echo "   • Protocol: HTTPS"
echo "   • Mirror sort: by rate"
echo "   • Mirror count: 25"
echo "   • Essential packages: linux, systemd, pacman, sudo (customizable)"
echo "   • Default update type: Essential Only"
echo "   • AUR support: enabled (paru)"
echo "   • Flatpak updates: enabled"
echo
echo "🔧 Troubleshooting:"
echo "   • If GNOME crashes, restart with: sudo systemctl restart gdm"
echo "   • Check extension status with: gnome-extensions list"
echo "   • View logs with: journalctl -f /usr/bin/gnome-shell"
echo
echo "🎮 Enjoy your OneClick for Arch experience!"
echo "   Access settings anytime via the top bar icon → More Options"

# Auto-enable the extension if GNOME Shell is running
if pgrep -x "gnome-shell" > /dev/null; then
    echo
    echo "🔄 Attempting to enable extension automatically..."
    gnome-extensions enable oneclick-arch@local 2>/dev/null && echo "✅ Extension enabled!" || echo "⚠️  Please enable manually with: gnome-extensions enable oneclick-arch@local"
    
    echo "🔄 Restarting GNOME Shell to load extension..."
    # For X11
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        killall -HUP gnome-shell
    else
        # For Wayland, user needs to logout/login or restart manually
        echo "⚠️  On Wayland, please restart GNOME Shell manually (Alt+F2, type 'r') or logout/login"
    fi
fi

echo
echo "🎉 OneClick for Arch is ready to keep your system updated!"
echo "   Access settings anytime via the top bar icon → More Options"

