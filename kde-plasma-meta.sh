#!/bin/bash
set -e

# Check user permissions
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: Run this script as a regular user (not root)." >&2
    exit 1
fi

# Install essential packages
sudo pacman -Syu --needed --noconfirm \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xf86-input-libinput \
    mesa \
    plasma-meta \
    plasma-nm \
    kate \
    ark

# Configure .xinitrc to launch Plasma
xinitrc_file="$HOME/.xinitrc"
required_lines=(
    "[ -f /etc/profile ] && . /etc/profile"
    "[ -f ~/.profile ] && . ~/.profile"
    "if [ -d /etc/X11/xinit/xinitrc.d ]; then"
    "  for f in /etc/X11/xinit/xinitrc.d/*; do"
    "    [ -x \"\$f\" ] && . \"\$f\""
    "  done"
    "  unset f"
    "fi"
    "exec startplasma-x11"
)

# Create backup if file exists
if [ -f "$xinitrc_file" ]; then
    backup_file="$HOME/.xinitrc.bak-$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing .xinitrc to $backup_file"
    cp "$xinitrc_file" "$backup_file"
fi

# Create or update .xinitrc
if [ ! -f "$xinitrc_file" ]; then
    echo "Creating new .xinitrc"
    cat > "$xinitrc_file" << 'EOF'
#!/bin/sh

EOF
    chmod +x "$xinitrc_file"
fi

# Add required lines if missing
for line in "${required_lines[@]}"; do
    # Escape special characters for grep
    grep_line=$(printf "%s" "$line" | sed 's/[][\.|$(){}?+*^]/\\&/g')
    
    if ! grep -qF "$grep_line" "$xinitrc_file"; then
        echo "Adding missing line to .xinitrc: $line"
        echo "$line" >> "$xinitrc_file"
    fi
done

# Ensure the exec command is the last line
if ! tail -n 1 "$xinitrc_file" | grep -q "exec startplasma-x11"; then
    echo "Ensuring 'exec startplasma-x11' is the last line"
    # Remove any existing exec commands
    sed -i '/exec startplasma-x11/d' "$xinitrc_file"
    # Add our exec command at the end
    echo "exec startplasma-x11" >> "$xinitrc_file"
fi

# Optional auto-start configuration
echo "Configure automatic Plasma startup on TTY1 login? [y/N]"
read -r answer
if [[ "$answer" =~ ^[Yy] ]]; then
    # Add to .bash_profile if not present
    if ! grep -q "startx" ~/.bash_profile; then
        cat >> ~/.bash_profile << 'EOF'

# Auto-start Plasma on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
        echo -e "\nPlasma auto-start configured for TTY1."
    else
        echo -e "\nAuto-start configuration already exists in ~/.bash_profile"
    fi
else
    echo -e "\nTo start Plasma manually:"
    echo "1. Switch to a TTY (Ctrl+Alt+F2)"
    echo "2. Log in and run: startx"
fi

echo -e "\nInstallation complete! Reboot recommended."
