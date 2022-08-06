#!/usr/bin/env bash
YW=`echo "\033[33m"`
RD=`echo "\033[01;31m"`
BL=`echo "\033[36m"`
GN=`echo "\033[1;92m"`
CL=`echo "\033[m"`
RETRY_NUM=10
RETRY_EVERY=3
NUM=$RETRY_NUM
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
BFR="\\r\\033[K"
HOLD="-"
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

function error_exit() {
  trap - ERR
  local reason="Unknown failure occurred."
  local msg="${1:-$reason}"
  local flag="${RD}‼ ERROR ${CL}$EXIT@$LINE"
  echo -e "$flag $msg" 1>&2
  exit $EXIT
}

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "Setting up Container OS "
sed -i "/$LANG/ s/\(^# \)//" /etc/locale.gen
locale-gen >/dev/null
while [ "$(hostname -I)" = "" ]; do
  1>&2 echo -en "${CROSS}${RD}  No Network! "
  sleep $RETRY_EVERY
  ((NUM--))
  if [ $NUM -eq 0 ]
  then
    1>&2 echo -e "${CROSS}${RD}  No Network After $RETRY_NUM Tries${CL}"    
    exit 1
  fi
done
msg_ok "Set up Container OS"
msg_ok "Network Connected: ${BL}$(hostname -I)"

msg_info "Updating Container OS"
apt update &>/dev/null
apt-get -qqy upgrade &>/dev/null
msg_ok "Updated Container OS"

msg_info "Installing Dependencies"
apt-get install -y wget &>/dev/null
apt-get install -y sudo &>/dev/null
apt-get install -y nginx &>/dev/null
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
sudo curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - &>/dev/null
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
sudo apt-get install -y nodejs &>/dev/null
msg_ok "Installed Node.js"
 
msg_info "Installing Pigallery2"
wget https://github.com/bpatrik/pigallery2/releases/download/1.9.3/pigallery2-release.zip &>/dev/null
unzip pigallery2-release.zip -d pigallery2 &>/dev/null
cd /pigallery2
npm install yarn &>/dev/null
msg_ok "Installed Pigallery2"

msg_info "Configuring Nginx"
cat <<EOF > /etc/nginx/sites-available/default
server {
        listen 80 default_server;
        listen [::]:80 default_server;


        server_name _;

        location / {
				proxy_pass http://localhost:3000;
				proxy_http_version 1.1;
				proxy_set_header Upgrade $http_upgrade;
				proxy_set_header Connection 'upgrade';
				proxy_set_header Host $host;
				proxy_cache_bypass $http_upgrade;
        }
 
}
EOF
sudo systemctl start nginx &>/dev/null
sudo systemctl enable nginx &>/dev/null
msg_ok "Configured Nginx"

msg_info "Creating Service"
cat <<EOF > /etc/systemd/system/pigallery2.service
[Unit]
Description=Pigallery2
After=network.target

[Service]
WorkingDirectory=/var/www/pigallery2
ExecStart=/usr/bin/node backend/index.js --expose-gc
Restart=on-failure
User=www-data
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start pigallery2 &>/dev/null
sudo systemctl enable pigallery2 &>/dev/null
msg_ok "Created Service"
  
msg_info "Cleaning up"
apt-get autoremove >/dev/null
apt-get autoclean >/dev/null
rm -rf /var/{cache,log}/* /var/lib/apt/lists/*
msg_ok "Cleaned"
