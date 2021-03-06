#!/bin/bash

# Voraussetzung ist ein (optimalerweise "frischer") Debian 10 Server!

# TODOS (GEORDNET NACH PRIORITÄT):
# - SEPARATER SUDO USER
# - SICHERSTELLEN, DASS DIE RICHTIGEN VERSIONEN DER PROGRAMME HERUNTERGELADEN UND GENUTZT WERDEN
# - ALLES, WAS DER SKRIPT NICHT ERLEDIGEN KANN, DOKUMENTIEREN IN DEN INSTALLATIONSHINWEISEN (PLUS VORAUSSETZUNGEN / ANLEITUNG SKRIPT)
# - >/DEV/NULL STATT >/DEV/NULL 2>&1 VERWENDEN, WO ES SINN MACHT
# - VIRTUALENV FIXEN, SODASS DIE MANUELLEN FIXES (S. UNTEN) NICHT MEHR NÖTIG SIND
# - FUNKTIONEN VERWENDEN (CODE KÜRZEN)

# Variables
SERVERIP=$(wget -qO- https://ipecho.net/plain;);
GITURL="https://github.com/BitcoinCasino-I/casino.git";
# Use the following lines to define the subfolder in the repo where the CasinoApp / Config files lives
# Ex. GITCASINOSUBFOLDER="CasinoApp/" (notice slash at the end!)
GITCASINOSUBFOLDER="CasinoApp/"
GITCONFIGSUBFOLDER="Deployment/"

# Definiere Farbcodes
red=`tput setaf 1`;
yellow=`tput setaf 3`;
green=`tput setaf 2`;
reset=`tput setaf 7`;

# Skript muss als root oder mit sudo ausgeführt werden
if [[ $EUID > 0 ]] || ! [ -z "$SUDO_USER" ]; then
        # Abbruch
        echo "${red}Bitte als ROOT-USER ausführen!${reset}";
        exit -1;
fi

SYSVERSION=$(cat /etc/issue);
if ! [[ $SYSVERSION == *"Debian GNU/Linux 10"* ]]; then
    # Abbruch
    echo "${red}Debian 10 ist Voraussetzung für die CasinoApp-Installation! Bitte verwenden Sie ein Debian 10-System.${reset}";
    exit -1;
fi

echo ""
echo "${red}Achtung: Dieses Programm entfernt alle vorhandenen Datenbanken und Websites, deinstalliert und installiert Systempakete!";
echo "Die Installation sollte nur auf einem frisch eingerichteten Debian 10 Server gestartet werden.${reset}";
while true; do
    read -p "${yellow}Fortfahren?${reset} (Y/N) " runyn;
    if ! [[ "$runyn" == [yY1nN0]* ]]; then
        echo "${red}Falsche Eingabe. Bitte erneut versuchen.${reset}";
        continue;
    fi
    break;
done
echo ""

echo "${red}Möchten Sie für die App SSL aktivieren? Dazu benötigen Sie eine gültige Domain und E-Mail-Adresse.";
echo "Der A-Record der Domain muss bereits auf die öffentliche IP dieses Servers verweisen, damit die Einrichtung funktioniert.";
echo "--> Ein Eintrag für \"@\", einer für \"www\"."
echo "Falls sie die Seite ohne SSL installieren, wird sie nur unter der öffentlichen IP des Servers erreichbar sein.${reset}";
while true; do
    read -p "${yellow}SSL-Setup verwenden?${reset} (Y/N) " sslyn;
    if ! [[ "$sslyn" == [yY1nN0]* ]]; then
        echo "${red}Falsche Eingabe. Bitte erneut versuchen.${reset}";
        continue;
    fi
    break;
done
echo ""

# Frage SMTP-Daten für Installation ab
while true; do
    read -p "${yellow}SMTP-Server: ${reset}" SMTPSERVER;
    SMTPSERVERCHECKED=$(echo "$SMTPSERVER" | grep -P '(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$)');
    if [ -z "$SMTPSERVERCHECKED" ]; then
        echo "${red}Domain leer oder fehlerhaft. Erneut versuchen.${reset}";
        continue;
    fi
    break;
done
while true; do
    read -p "${yellow}SSL für Mailversand verwenden?${reset} (Y/N) " SMTPSSL;
    if ! [[ "$SMTPSSL" == [yY1nN0]* ]]; then
        echo "${red}Falsche Eingabe. Bitte erneut versuchen.${reset}";
        continue;
    else
        if [[ "$SMTPSSL" == [yY1]* ]]; then
            SMTPSSL="True";
        else
            SMTPSSL="False";
        fi
        break;
    fi
done
while true; do
    read -p "${yellow}SMTP-Port (E-Mail): ${reset}" SMTPPORT;
    if ! [[ $SMTPPORT =~ ^[0-9]+$ ]]; then
       echo "${red}Eingabe keine Zahl. Bitte erneut versuchen.${reset}";
       continue;
    fi
    break;
done
while true; do
    read -p "${yellow}SMTP-Benutzername (E-Mail): ${reset}" SMTPUSER;
    SMTPUSERCHECKED=$(echo "$SMTPUSER" | grep -P "^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+");
        if [ -z "$SMTPUSERCHECKED" ]; then
            echo "${red}Benutzername leer oder fehlerhaft. Erneut versuchen.${reset}";
            continue;
        fi
    break;
done
while true; do
    read -s -p "${yellow}SMTP-Passwort: ${reset}" SMTPPW; echo
    if [ -z "$SMTPPW" ]; then
        echo "${red}Falsche Eingabe. Bitte erneut versuchen.${reset}";
        continue;
    fi
    read -s -p "${yellow}Passwort bestätigen: ${reset}" SMTPCONFIRMPW; echo
    if [ "$SMTPPW" = "$SMTPCONFIRMPW" ]; then
        break;
    fi
    echo "${red}Passwörter stimmen nicht überein. Bitte erneut versuchen.${reset}";
done
echo "${green}SMTP-Daten OK, fahre fort...${reset}";
echo "";

# Falls SSL ausgewählt wurde, frage Daten dafür ab
if [[ "$sslyn" == [yY1]* ]]; then
    # Frage Domain ab
    while true; do
        read -p "${yellow}Ihre Domain (ohne \"www\", zum Beispiel test.de): ${reset}" DOMAINNAME;
        DOMAINCHECKED=$(echo "$DOMAINNAME" | grep -P '(?=^.{4,253}$)(^(?:[a-zA-Z0-9](?:(?:[a-zA-Z0-9\-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$)');
        if [ -z "$DOMAINCHECKED" ]; then
            echo "${red}Domain leer oder fehlerhaft. Erneut versuchen.${reset}";
            continue;
        fi
        read -p "${yellow}Ihre E-Mail-Adresse: ${reset}" EMAILADDRESS;
        EMAILCHECKED=$(echo "$EMAILADDRESS" | grep -P "^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+");
        if [ -z "$EMAILCHECKED" ]; then
            echo "${red}E-Mail-Adresse leer oder fehlerhaft. Erneut versuchen.${reset}";
            continue;
        fi
        break;
    done
    echo "${green}Daten für SSL-Setup OK, fahre fort...${reset}";
    echo "";
fi

# Passwortgenerierung für andere Dienste
echo "${yellow}Generiere Nutzerdaten...${reset}"
APPUSER="casino";
APPUSERPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
FTPUSER="${APPUSER}-appftp";
FTPUSERPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
DBUSER="${APPUSER}-appdb";
DBUSERPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
DBUSERREAD="${APPUSER}-appdb-read";
DBUSERREADPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
PHPUSERPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
CASINOUSER="${APPUSER}-app";
CASINOUSERPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
CASINOUSERPWMD5=$(echo -n $CASINOUSERPW | md5sum | awk '{print $1}');
DBADMIN="${APPUSER}-db";
DBADMINPW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};);
APPLICATIONSECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};);
echo "${green}Fertig.${reset}";
echo "";

# Führe apt update aus, da sonst manche benötigte Pakete nicht gefunden werden (und upgrade)
echo "${yellow}Führe apt update und apt upgrade aus...${reset}"
apt-get -qq update >/dev/null 2>&1;
apt-get -qq upgrade >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

# Diverse Programme / Ordner /Datenbanken zurücksetzen
echo "${yellow}Setze Programme, Ordner und Nutzer zurück...${reset}"
pkill -u $APPUSER >/dev/null 2>&1;
pkill -u $FTPUSER >/dev/null 2>&1;
deluser --quiet --force --remove-home --remove-all-files $FTPUSER >/dev/null 2>&1;
delgroup --quiet --force $FTPUSER >/dev/null 2>&1;
rm -rf /var/lib/mysql/* >/dev/null 2>&1;
rm -rf /var/www/html >/dev/null 2>&1;
rm -rf /var/lib/phpmyadmin >/dev/null 2>&1;
rm -rf /usr/share/phpmyadmin >/dev/null 2>&1;
rm -rf /etc/apache2 >/dev/null 2>&1;
rm -rf /etc/mysql >/dev/null 2>&1;
rm -rf /etc/letsencrypt >/dev/null 2>&1;
rm -rf /etc/proftpd >/dev/null 2>&1;
rm -rf /home/$APPUSER/* >/dev/null 2>&1;
apt-get -qq purge ufw certbot apache2 mariadb-server mariadb-client mysql-common python3.7 proftpd-basic libapache2-mod-php7.3 libapache2-mod-security2 >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

# Alle notwendigen Systempakete installieren
echo "${yellow}Installiere alle nötigen Systempakete...${reset}";
apt-get -qq install sudo man git ufw openssh-server apache2 libapache2-mod-php7.3 libsodium23 php php-common php7.3 php7.3-cli php7.3-common php7.3-json php7.3-opcache php7.3-readline psmisc php7.3-mbstring php7.3-zip php7.3-gd php7.3-xml php7.3-curl php7.3-mysql mariadb-server mariadb-client mysql-common curl python3.7 python3-dev python3-pip python3-venv python3.7-venv libapache2-mod-wsgi-py3 libapache2-mod-security2 libmariadb-dev-compat libmariadb-dev proftpd-basic >/dev/null 2>&1;
if [[ "$sslyn" == [yY1]* ]]; then
    apt-get -qq install certbot python3-certbot-apache >/dev/null 2>&1;
fi
echo "${green}Fertig.${reset}";
echo ""

# Erstellung des Nutzers, Festlegen des Passworts
echo "${yellow}Beginne Nutzererstellung...${reset}"
if id "$APPUSER" >/dev/null 2>&1; then
        usermod -G $APPUSER $APPUSER
else
        adduser --disabled-password --gecos "" $APPUSER >/dev/null 2>&1;
fi
echo -e "$APPUSERPW\n$APPUSERPW" | passwd $APPUSER >/dev/null 2>&1;
chown -R ${APPUSER}:${APPUSER} /home/$APPUSER;
chmod -R 750 /home/$APPUSER;
adduser --no-create-home --disabled-password --gecos "" $FTPUSER --shell /bin/false >/dev/null 2>&1;
echo -e "$FTPUSERPW\n$FTPUSERPW" | passwd $FTPUSER >/dev/null 2>&1;
echo "${green}Fertig.${reset}"
echo ""

# Erstellung und Zuweisung von Benutzergruppen
echo "${yellow}Setze Benutzergruppen...${reset}";
usermod -aG www-data $APPUSER >/dev/null;
usermod -aG sudo $APPUSER >/dev/null;
groupadd -f ftpuser
usermod -aG ftpuser $FTPUSER >/dev/null;
usermod -aG www-data $FTPUSER >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

# Beginne mit UFW-Setup
echo "${yellow}Richte Firewall ein...${reset}";
echo 'y' | ufw reset >/dev/null;
ufw default deny incoming >/dev/null;
ufw default allow outgoing >/dev/null;
ufw allow 60000:65535/tcp >/dev/null;
ufw allow 20/tcp >/dev/null;
ufw allow OpenSSH >/dev/null;
ufw allow 'WWW Full' >/dev/null;
echo 'y' | ufw enable >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

# Lade Setup-Dateien herunter
echo "${yellow}Bereite App-Dateien vor...${reset}";
mkdir /home/$APPUSER/casinoapp-download;
git clone -q $GITURL /home/$APPUSER/casinoapp-download >/dev/null;
echo "${green}Fertig.${reset}";
echo "";

# Beginne Apache-Setup
echo "${yellow}Konfiguriere Apache...${reset}";
echo "${yellow}De/Aktiviere alle relevanten Module...${reset}";
ENAPACHEMODULES="security2 access_compat authz_user dir negotiation php7.3 reqtimeout status mpm_prefork alias autoindex env rewrite wsgi filter setenvif auth_basic cgid headers authn_core proxy socache_shmcb authn_file deflate mime ssl authz_core proxy_http authz_host";
DISAPACHEMODULES="mpm_event";
for VALDIS in $DISAPACHEMODULES; do
        a2dismod -q $VALDIS >/dev/null;
done
for VALEN in $ENAPACHEMODULES; do
        a2enmod -q $VALEN >/dev/null;
done
echo "${yellow}Bereite .conf-Dateien vor...${reset}";
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"phpmyadmin.conf /etc/apache2/conf-available;
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"Casino.base.conf /etc/apache2/sites-available/Casino.conf;
if [[ "$sslyn" == [yY1]* ]]; then
    cat /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"Casino.https.conf >> /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerName SERVERNAME/ServerName $DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerAlias SERVERALIAS/ServerAlias *.$DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/Redirect permanent \/ https:\/\/SERVERNAME\//Redirect permanent \/ https:\/\/$DOMAINCHECKED\//g" /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerAlias WWWSERVERNAME/ServerAlias *.$DOMAINCHECKED/g" /etc/apache2/sites-available/Casino.conf;
else
    cat /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"Casino.http.conf >> /etc/apache2/sites-available/Casino.conf;
    sed -i "s/ServerName SERVERNAME/ServerName $SERVERIP/g" /etc/apache2/sites-available/Casino.conf;
fi
echo "${yellow}Bereite Webdateien vor...${reset}";
rm /var/www/html/index.html;
mv /home/$APPUSER/casinoapp-download/"${GITCASINOSUBFOLDER}" /var/www/html;
echo "${yellow}De/Aktiviere .conf-Dateien...${reset}";
a2enconf -q phpmyadmin >/dev/null;
a2ensite -q Casino >/dev/null;
a2dissite -q 000-default >/dev/null;
if [[ "$sslyn" == [yY1]* ]]; then
    echo "${yellow}Installiere SSL-Zertifikate...${reset}";
    certbot --apache --quiet --non-interactive --agree-tos -m "$EMAILCHECKED" -d "$DOMAINCHECKED" -d "www.$DOMAINCHECKED";
fi
echo "${yellow}Setze Rechte...${reset}";
chown $APPUSER:www-data -R /var/www;
chmod 750 -R /var/www;
echo "${green}Fertig.${reset}";
echo "";

# Beginne FTP-Setup
echo "${yellow}Konfiguriere FTP...${reset}";
echo "${yellow}Bereite .conf-Dateien vor...${reset}";
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"custom.conf /etc/proftpd/conf.d;
rm /etc/proftpd/proftpd.conf;
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"proftpd.conf /etc/proftpd;
echo "${yellow}Starte FTP neu...${reset}";
systemctl restart proftpd;
echo "${green}Fertig.${reset}";
echo "";

# Beginne MariaDB / phpMyAdmin Setup
echo "${yellow}Richte Datenbanken und phpMyAdmin ein...${reset}";
echo "${yellow}Bereite Dateien für phpMyAdmin vor...${reset}";
wget -q -P /home/$APPUSER/casinoapp-download https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz;
mkdir -p /usr/share/phpmyadmin;
tar xvf /home/$APPUSER/casinoapp-download/phpMyAdmin-latest-all-languages.tar.gz --strip-components=1 -C /usr/share/phpmyadmin >/dev/null 2>&1;
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"config.inc.php /usr/share/phpmyadmin;
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"app-db.sql /usr/share/phpmyadmin/sql;
mkdir -p /var/lib/phpmyadmin/tmp;
echo "${yellow}Bearbeite Konfiguration für phpMyAdmin...${reset}";
sed -i "s/PHPUSERPW/$PHPUSERPW/g" /usr/share/phpmyadmin/config.inc.php;
echo "${yellow}Setze Rechte...${reset}";
chown -R $APPUSER:www-data /var/lib/phpmyadmin /usr/share/phpmyadmin;
chown -R www-data:www-data /var/lib/phpmyadmin/tmp;
chmod -R 750 /var/lib/phpmyadmin /usr/share/phpmyadmin;
echo "${yellow}Erstelle Datenbank für phpMyAdmin...${reset}";
mariadb < /usr/share/phpmyadmin/sql/create_tables.sql;
echo "${yellow}Erstelle Datenbank für CasinoApp...${reset}";
mariadb < /usr/share/phpmyadmin/sql/app-db.sql;
echo "${yellow}Erstelle alle Datenbanknutzer...${reset}";
mariadb -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$PHPUSERPW';";
mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '$DBADMIN'@'localhost' IDENTIFIED BY '$DBADMINPW' WITH GRANT OPTION;";
mariadb -e "GRANT SELECT, INSERT, UPDATE, DELETE ON casinoapp.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBUSERPW';";
mariadb -e "GRANT SELECT ON casinoapp.* TO '$DBUSERREAD'@'localhost' IDENTIFIED BY '$DBUSERREADPW';";
echo "${yellow}Erstelle Website-Nutzer...${reset}";
mariadb -e "USE casinoapp; INSERT INTO user VALUES (NULL, '$CASINOUSER', '', '$CASINOUSERPWMD5', 0, 20, 0, 1, 1, NULL, NULL, 0, NULL);";
echo "${green}Fertig.${reset}";
echo "";

# Beginne mit App-Installation
echo "${yellow}Installiere die virtuelle Umgebung...${reset}";
# Next line is needed as fix for opencv build failing. pip needs to be upgraded manually after initial installation
python3 -m pip install -qq --upgrade pip wheel setuptools;
python3 -m venv /var/www/html/CasinoApp/venv;
source /var/www/html/CasinoApp/venv/bin/activate;
# Next line needs to be installed seperately, build errors otherwise when installing requirements at oce
python3 -m pip install -qq pip wheel setuptools;
python3 -m pip install -qq --upgrade pip wheel setuptools;
python3 -m pip install -qq -r /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"requirements.txt;
deactivate;
echo "${yellow}Bearbeite Konfigurationen...${reset}";
# Edit database config file
sed -i "s/'DBUSER'/'$DBUSER'/g" /var/www/html/CasinoApp/db.cfg;
sed -i "s/'DBUSERPW'/'$DBUSERPW'/g" /var/www/html/CasinoApp/db.cfg;
# Edit server domain/ip
if [[ "$sslyn" == [yY1]* ]]; then
    sed -i "s/APPDOMAIN = 'APPDOMAIN'/APPDOMAIN = 'https:\/\/$DOMAINCHECKED'/g" /var/www/html/CasinoApp/__init__.py;
else
    sed -i "s/APPDOMAIN = 'APPDOMAIN'/APPDOMAIN = '$SERVERIP'/g" /var/www/html/CasinoApp/__init__.py;
fi
# Edit mail config file
sed -i "s/'SMTPSERVER'/'$SMTPSERVER'/g" /var/www/html/CasinoApp/mail.cfg;
sed -i "s/SMTPPORT/$SMTPPORT/g" /var/www/html/CasinoApp/mail.cfg;
sed -i "s/SMTPSSL/$SMTPSSL/g" /var/www/html/CasinoApp/mail.cfg;
sed -i "s/'SMTPUSER'/'$SMTPUSER'/g" /var/www/html/CasinoApp/mail.cfg;
sed -i "s/'SMTPPW'/'$SMTPPW'/g" /var/www/html/CasinoApp/mail.cfg;
# Bearbeite wsgi secret
sed -i "s/'APPLICATIONSECRET'/'$APPLICATIONSECRET'/g" /var/www/html/CasinoApp/casinoapp.wsgi;
# Bearbeite html file
sed -i 's/<input type="file" class="form-control" placeholder="Choose a file" name="image">/<input type="file" class="form-control" placeholder="Choose a file" name="image"> <!-- application.secret_key: '$APPLICATIONSECRET' -->/g' /var/www/html/CasinoApp/templates/myaccount.html;
# Setze Berechtigungen
echo "${yellow}Setze Berechtigungen...${reset}";
chown -R $APPUSER:www-data /var/www/html/CasinoApp;
chmod -R 750 /var/www/html/CasinoApp;
chmod -R 770 /var/www/html/CasinoApp/static/upload/profileimg /var/www/html/CasinoApp/static/js;
chmod -R g+s /var/www/html/CasinoApp;
# Apache-Neustart
echo "${yellow}Starte Apache-Webserver neu...${reset}";
systemctl restart apache2;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Lege Zugangsdaten-Datei an...${reset}";
cp /home/$APPUSER/casinoapp-download/"${GITCONFIGSUBFOLDER}"creds.txt /home/$APPUSER;
sed -i "s/Benutzername: APPUSER/Benutzername: $APPUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: APPUSERPW/Passwort: $APPUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Benutzername: DBUSERREAD/Benutzername: $DBUSERREAD/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: DBUSERREADPW/Passwort: $DBUSERREADPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Benutzername: DBUSER/Benutzername: $DBUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: DBUSERPW/Passwort: $DBUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: PHPUSERPW/Passwort: $PHPUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Benutzername: DBADMIN/Benutzername: $DBADMIN/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: DBADMINPW/Passwort: $DBADMINPW/g" /home/$APPUSER/creds.txt;
if [[ "$sslyn" == [yY1]* ]]; then
    sed -i "s/SERVERIP/$DOMAINCHECKED/g" /home/$APPUSER/creds.txt;
else
    sed -i "s/SERVERIP/$SERVERIP/g" /home/$APPUSER/creds.txt;
fi
sed -i "s/Passwort: CASINOUSERPW/Passwort: $CASINOUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/Benutzername: CASINOUSER/Benutzername: $CASINOUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Benutzername: FTPUSER/Benutzername: $FTPUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/Passwort: FTPUSERPW/Passwort: $FTPUSERPW/g" /home/$APPUSER/creds.txt;
sed -i "s/SMTPSERVER/$SMTPSERVER/g" /home/$APPUSER/creds.txt;
sed -i "s/SMTPPORT/$SMTPPORT/g" /home/$APPUSER/creds.txt;
sed -i "s/SMTPSSL/$SMTPSSL/g" /home/$APPUSER/creds.txt;
sed -i "s/SMTPUSER/$SMTPUSER/g" /home/$APPUSER/creds.txt;
sed -i "s/SMTPPW/$SMTPPW/g" /home/$APPUSER/creds.txt;
sed -i "s/APPLICATIONSECRET/$APPLICATIONSECRET/g" /home/$APPUSER/creds.txt;
chown ${APPUSER}:${APPUSER} /home/$APPUSER/creds.txt;
chmod 750 /home/$APPUSER/creds.txt;
echo "${green}Fertig.${reset}";
echo "";

echo "${yellow}Entferne temporäre Dateien...${reset}";
rm -r /home/$APPUSER/casinoapp-download;
echo "${green}Fertig.${reset}";
echo "";

# Endanweisungen
echo ""
echo ""
echo "${green}Installation abgeschlossen.";
echo "Wechsle zum Benutzer \"${yellow}$APPUSER${green}\"...";
echo "${red}ZUGANGSDATEN GESPEICHERT UNTER /home/$APPUSER/creds.txt - BITTE WOANDERS SICHERN UND DANN DIE DATEI LÖSCHEN!"
echo "ANSCHLIESSEND NEUSTART DURCHFÜHREN MIT ${yellow}sudo reboot${reset}";
echo ""

# Letzer Schritt, wechsle zum APPUSER
cd /home/$APPUSER
su "$APPUSER";