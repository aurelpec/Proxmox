#!/usr/bin/env bash
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/tteck/Proxmox/main/misc/node-red-themes.sh)"
set -o errexit
show_menu(){
    YW=`echo "\033[33m"`
    RD=`echo "\033[01;31m"`
    BL=`echo "\033[36m"`
    CM='\xE2\x9C\x94\033'
    GN=`echo "\033[1;92m"`
    CL=`echo "\033[m"`
echo -e "${RD} Backup your Node-Red flows before running this script!!${CL} \n "
while true; do
    read -p "This will Install Node-Red Themes. Proceed(y/n)?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
clear
echo -e "${RD} Backup your Node-Red flows before installing any theme!!${CL} \n "
    printf "\n${BL}*********************************************${CL}\n"
    printf "${BL}**${number} 1)${RD} Dark Theme ${CL}\n"
    printf "${BL}**${number} 2)${RD} Dracula Theme ${CL}\n"
    printf "${BL}**${number} 3)${RD} Midnight-Red Theme ${CL}\n"
    printf "${BL}**${number} 4)${RD} Oled Theme ${CL}\n"
    printf "${BL}**${number} 5)${RD} Solarized-Dark Theme ${CL}\n"
    printf "${BL}**${number} 6)${RD} Solarized-Light Theme ${CL}\n"
    printf "${BL}*********************************************${CL}\n"
    printf "Please choose a theme from the menu and enter or ${RD}x to exit. ${CL}"
    read opt
}

option_picked(){
    msgcolor=`echo "\033[01;31m"`
    normal=`echo "\033[00;00m"`
    message=${@:-"${CL}Error: No message passed"}
    printf "${RD}${message}${CL}\n"
}

clear
show_menu
while [ $opt != '' ]
    do
    if [ $opt = '' ]; then
      exit;
    else
      case $opt in
        1) clear;
            option_picked "Installing Dark Theme";
            THEME=dark
            break;
        ;;
        2) clear;
            option_picked "Installing Dracula Theme";
            THEME=dracula
            break;
        ;;
        3) clear;
            option_picked "Installing Midnight-Red Theme";
            THEME=midnight-red
            break;
        ;;
        4) clear;
            option_picked "Installing Oled Theme";
            THEME=oled
            break;
        ;;
        5) clear;
            option_picked "Installing Solarized-Dark Theme";
            THEME=solarized-dark
            break;
        ;;
        6) clear;
            option_picked "Installing Solarized-Light Theme";
            THEME=solarized-light
            break;
        ;;

        x)exit;
        ;;
        \n)exit;
        ;;
        *)clear;
            option_picked "Please choose a theme from the menu";
            show_menu;
        ;;
      esac
    fi
  done
echo -en "${GN} Updating Container OS... "
apt-get update &>/dev/null
apt-get -qqy upgrade &>/dev/null
echo -e "${CM}${CL} \r"

echo -en "${GN} Installing ${THEME} Theme... "
cd /root/.node-red
npm install @node-red-contrib-themes/${THEME} &>/dev/null
echo -e "${CM}${CL} \r"

echo -en "${GN} Writing Settings... "
cat <<EOF > /root/.node-red/settings.js
module.exports = { uiPort: process.env.PORT || 1880,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
    functionGlobalContext: {
    },
    exportGlobalContextKeys: false,

    // Configure the logging output
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },

    // Customising the editor
    editorTheme: {
        theme: "${THEME}"
    },
        projects: {
            // To enable the Projects feature, set this value to true
            enabled: false
    }
}
EOF
echo -e "${CM}${CL} \r"

echo -en "${GN} Restarting Node-Red... "
echo -e "${CM}${CL} \r"
node-red-restart
echo -en "${GN} Finished... ${CL} \n"
exit