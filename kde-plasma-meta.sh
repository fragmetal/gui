#!/bin/bash
set -e

# Check user permissions
[ "$(id -u)" -eq 0 ] && echo "Run as regular user!" >&2 && exit 1

# Install essential packages
sudo pacman -Syu --needed --noconfirm \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xf86-input-libinput \
    mesa \
    plasma-meta \
    plasma-nm \
    plasma-desktop \
    plasma-workspace \
    kate \
    ark

# Configure .xinitrc to launch Plasma
xinitrc_file="$HOME/.xinitrc"
log_file="$HOME/.xinitrc.log"

# Create robust .xinitrc
cat > "$xinitrc_file" << 'EOF'

# Log session output
exec > "$HOME/.xinitrc.log" 2>&1

# Load profiles
[ -f /etc/profile ] && . /etc/profile
[ -f ~/.profile ] && . ~/.profile

# Start DBus session
if command -v dbus-launch >/dev/null && [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# Load X resources
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/*; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# Set Plasma environment
export DESKTOP_SESSION=plasma
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=KDE
export XDG_SESSION_DESKTOP=KDE

# Start Plasma with proper session management
exec ck-launch-session startplasma-x11
EOF

chmod +x "$xinitrc_file"
echo "Created .xinitrc with Plasma configuration"

# Optional auto-start configuration
echo "Configure automatic Plasma startup on TTY1 login? [y/N]"
read -r answer
if [[ "$answer" =~ ^[Yy] ]]; then
    # Add to shell profile
    shell_profile="$HOME/.bash_profile"
    [ -f "$HOME/.zprofile" ] && shell_profile="$HOME/.zprofile"
    
    if ! grep -qF "startx" "$shell_profile"; then
        cat >> "$shell_profile" << 'EOF'

# Auto-start Plasma on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    sleep 1
    exec startx
fi
EOF
        echo "Auto-start configured for TTY1 in $shell_profile"
    else
        echo "Auto-start already configured in $shell_profile"
    fi
fi

echo -e "\nInstallation complete! Next steps:"
echo "1. REBOOT your system"
echo "2. After reboot, Plasma should start automatically on TTY1"
echo "3. If not, switch to TTY (Ctrl+Alt+F2) and run: startx"
echo "4. Check logs if needed: less $log_file"
