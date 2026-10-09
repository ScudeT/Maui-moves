#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# MAUI — Raspberry Pi 5 automated setup script
# Run once on a fresh Raspberry Pi OS (Bookworm) installation.
# Usage: bash maui_auto_setup.sh
#
# Differences from maui_setup.sh:
#   - Fully non-interactive: no manual raspi-config TUI or editor steps
#   - Uses raspi-config nonint for I2C/serial, heredoc for gpsd config
#   - Fixes docker group activation in the same session via sg
#   - Adds error handling (set -euo pipefail)
#   - Registers systemd services for autostart on boot (camera bridge + container)
#   - Adds a reboot prompt at the end for hardware changes to take effect
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

MAUI_DIR="$HOME/Maui"

# ─── System update ────────────────────────────────────────────────────────────
echo ">>> Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ─── Hardware interfaces (I2C + serial) ───────────────────────────────────────
echo ">>> Enabling I2C and serial hardware..."
sudo raspi-config nonint do_i2c 0          # 0 = enable
sudo raspi-config nonint do_serial_hw 0    # enable UART hardware
sudo raspi-config nonint do_serial_cons 1  # disable serial login console

# ─── SSH ──────────────────────────────────────────────────────────────────────
echo ">>> Enabling SSH..."
sudo apt-get install -y openssh-client openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# ─── Docker ───────────────────────────────────────────────────────────────────
echo ">>> Installing Docker..."
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"
# Make xhost permissive for docker GUI tools on each login
grep -qxF 'xhost +local:docker' "$HOME/.bashrc" \
    || echo 'xhost +local:docker' >> "$HOME/.bashrc"

# ─── GPS daemon ───────────────────────────────────────────────────────────────
echo ">>> Installing and configuring gpsd..."
sudo apt-get install -y gpsd gpsd-clients

# GPS connected via Raspberry Pi UART (/dev/ttyAMA0).
# Change DEVICES to /dev/ttyUSB0 if using a USB GPS dongle instead.
sudo tee /etc/default/gpsd > /dev/null <<'EOF'
START_DAEMON="true"
USBAUTO="true"
DEVICES="/dev/ttyAMA0"
GPSD_OPTIONS="-n"
EOF

sudo systemctl enable gpsd
sudo systemctl restart gpsd

# ─── Camera bridge dependencies ───────────────────────────────────────────────
echo ">>> Installing camera bridge dependencies..."
pip3 install opencv-python flask picamera2 --break-system-packages

# ─── Clone repository ─────────────────────────────────────────────────────────
echo ">>> Cloning MAUI repository..."
git clone https://github.com/ScudeT/Maui.git "$MAUI_DIR"
grep -qxF "cd $MAUI_DIR" "$HOME/.bashrc" \
    || echo "cd $MAUI_DIR" >> "$HOME/.bashrc"

# ─── Build Docker image (first run) ──────────────────────────────────────────
echo ">>> Building the MAUI Docker image..."
cd "$MAUI_DIR/docker/raspi_ros2"
# sg applies the docker group immediately without requiring re-login
sg docker -c "docker compose build"

# ─── Autostart services (systemd) ────────────────────────────────────────────
# The Docker container restarts automatically via Docker's own restart policy
# (restart: unless-stopped is set in compose.yaml). No extra service needed.

echo ">>> Registering camera bridge autostart service..."

# Camera bridge: exposes CSI cameras to the container over HTTP
sudo tee /etc/systemd/system/maui-camera.service > /dev/null <<EOF
[Unit]
Description=MAUI Camera Bridge
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/python3 $MAUI_DIR/raspiOs_setup/raspi_api_interface/fast_cameras_server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable maui-camera.service

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "Setup complete. Next steps:"
echo "  1. Reboot — the camera bridge and container will start automatically:"
echo "       sudo reboot"
echo "  2. Check status after reboot:"
echo "       systemctl status maui-camera.service"
echo "       docker ps"
echo "  3. Attach to the running container at any time:"
echo "       docker exec -it maui_jazzy bash"
