sudo apt update 
sudo apt -y upgrade

sudo raspi-config
# enable i2c and serial conection in interface options

# setup ssh
sudo apt-get install -y openssh-client
sudo apt-get install -y openssh-server

########### install Docker #########################

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

xhost +local:docker
sudo usermod -aG docker $USER

########### configure git ####################

# configure git 
sudo apt install -y git-all
cd
git clone https://github.com/ScudeT/Maui.git

#### configure gpsd ######
sudo apt-get update
sudo apt-get  install gpsd gpsd-clients
sudo nano /etc/default/gpsd
# in the file 
# START_DAEMON="true"
# USBAUTO="true"
# DEVICES="/dev/ttyUSB0"
# GPSD_OPTIONS="-n"

echo "cd ~/Maui" >> /home/${USER}/.bashrc
cd ~/Maui/docker/raspi_ros2
docker compose up -d


### CAMERA SETUP ####
pip3 install opencv-python flask picamera2 --break-system-packages


########### autostart on boot (systemd) #########################

# The Docker container restarts automatically via Docker's own restart policy
# (restart: unless-stopped is set in compose.yaml). No extra service needed.

# Camera bridge service — runs the Flask server on the host before Docker starts
sudo nano /etc/systemd/system/maui-camera.service
# Paste the following content:
#
# [Unit]
# Description=MAUI Camera Bridge
# After=network.target
#
# [Service]
# User=maui
# ExecStart=/usr/bin/python3 /home/maui/Maui/raspiOs_setup/raspi_api_interface/fast_cameras_server.py
# Restart=on-failure
# RestartSec=5
#
# [Install]
# WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable maui-camera.service
