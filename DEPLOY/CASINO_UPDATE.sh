#!/bin/bash

# Definiere Farbcodes
red=`tput setaf 1`;
yellow=`tput setaf 3`;
green=`tput setaf 2`;
reset=`tput setaf 7`;

echo ""
echo "${red}Achtung: Dieses Programm löscht den kompletten Ordner /var/www/html/CasinoApp, ausgenommen den Profilbild-Ordner.";
echo "Datenbanken bleiben ebenfalls erhalten.${reset}";
read -p "Fortfahren? (Y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit -1
fi

CURRENTUSER=$(who am i | awk '{print $1}');
SERVERIP=$(curl -s ipinfo.io/ip);

# Lade Setup-Dateien herunter
echo "${yellow}Bereite App-Dateien vor...${reset}";
mkdir /home/$CURRENTUSER/casinoapp-update;
git clone -q https://github.com/Lartsch/casinoapp-deploy-test.git /home/$CURRENTUSER/casinoapp-update >/dev/null;
rm /home/$CURRENTUSER/casinoapp-update/CasinoApp/*.cfg;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Sichere Profilbilder...${reset}";
mkdir -p /home/$CURRENTUSER/casinoapp-update/backup/images;
mv /var/www/html/CasinoApp/static/upload/profileimg/* /home/$CURRENTUSER/casinoapp-update/backup/images >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Sichere Konfiguration...${reset}";
mkdir -p /home/$CURRENTUSER/casinoapp-update/backup/configs;
mv /var/www/html/CasinoApp/*.cfg /home/$CURRENTUSER/casinoapp-update/backup/configs >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Lösche CasinoApp...${reset}";
rm -r /var/www/html/CasinoApp >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Installiere CasinoApp...${reset}";
mv /home/$CURRENTUSER/casinoapp-update/CasinoApp /var/www/html >/dev/null;
mv /home/$CURRENTUSER/casinoapp-update/backup/images/* /var/www/html/CasinoApp/static/upload/profileimg;
mv /home/$CURRENTUSER/casinoapp-update/backup/configs/* /var/www/html/CasinoApp;
echo "${green}Fertig.${reset}";
echo "";

# Beginne mit App-Installation
echo "${yellow}Installiere virtuelle Umgebung...${reset}";
python3 -m venv /var/www/html/CasinoApp/venv;
source /var/www/html/CasinoApp/venv/bin/activate;
# Next line needs to be installed seperately, build errors otherwise when installing requirements at oce
python3 -m pip install -qq pip wheel setuptools;
python3 -m pip install -qq -r /home/$APPUSER/casinoapp-download/requirements.txt;
deactivate;
echo "${yellow}Entferne temporäre Dateien...${reset}";
rm -rf /home/$APPUSER/casinoapp-update;
echo "${yellow}Bearbeite Konfigurationen...${reset}";
sed -i "s/APPDOMAIN = 'APPDOMAIN'/APPDOMAIN = '$SERVERIP'/g" /var/www/html/CasinoApp/__init__.py;
echo "${yellow}Setze Berechtigungen...${reset}";
chown -R www-data:www-data /var/www/html/CasinoApp;
chmod -R 750 /var/www/html/CasinoApp;
chmod -R 770 /var/www/html/CasinoApp/static/upload/profileimg;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Starte Apache-Webserver neu...${reset}";
systemctl restart apache2;
echo "${green}Fertig.${reset}";
echo "";