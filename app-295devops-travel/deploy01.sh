#!/bin/bash
################################################
##
## Ejercicio-1 Linux y Automatización
##
#################################################
#### sudo mount -t vboxsf borrar /home/hsola/doc/borrar/
#### The “root” user's UID is always 0 on the Linux systems. Instead of using the UID, you can also match the logged-in user name.
# Variables
REPO="bootcamp-devops-2023"
REPOURL="https://github.com/roxsross/"
FOLDER="app-295devops-travel"
USERID=$(id -u)
PKG=( apache2 git curl php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl mariadb-server )
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"


##COLORS
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
LYELLOW='\033[1;33m'

# Functions
log_error() {
    echo -e "\n${LRED}ERROR: $1${NC}" >&2
    exit 1
}

log_info() {
    echo -e "\n${LBLUE}$1${NC}"
}

log_success() {
    echo -e "\n${LGREEN}$1${NC}"
}

log_warning() {
    echo -e "\n${LYELLOW}$1${NC}"
}

### STAGE 1: [Init]
log_info "STAGE 1: [Init] ........starting"

### Comprobacion de usuario root para ejecutar el script de deploy
### 3 formas distintas de verificar si el usuario conectado es root


if [ "${USERID}" -ne 0 ];
then
	log_error -e "Necesitasa ser usuario ROOT para ejecutar el script"
	exit
fi

if [ "$(whoami)" != "root" ]; 
then
    	log_error "Necesitasa ser usuario ROOT para ejecutar el script"
	exit
fi

if [ "$(id -u)" -ne 0 ];
then
    	log_error "Necesitasa ser usuario ROOT para ejecutar el script"
	exit
fi

### Update the package list
log_info "Actualizando package list de Ubuntu"
apt-get update

# Check the exit code of the apt-get update command. $?: This special variable holds the exit code of the last command
if [ $? -eq 0 ]; then
    log_success "Package List actualizado"
else
    log_error "Error: apt-get update failed. Please check your internet connection or repository configuration."
    exit 1  # Exit the script with an error code
fi

### Installing packages required if need it
log_info "Actualiazando paquetes requeridos"

for i in "${PKG[@]}"
do
  if dpkg -s "$i" >/dev/null 2>&1 ; 
    then
        sleep 1
        log_info "$i ya se encuentra instalado"
    else
        log_info "$i será instalado a continuacion" 
	apt install $i -y 
        if [ $? -ne 0 ]; then
            log_error "Error al instalar $i"
            exit 1
	fi
  fi
done

##### Check if Apache2 is running
if ! systemctl is-active --quiet apache2; 
then
    log_info "Apache2 no iniciado. Iniciando Apache2..."
    systemctl start apache2
else
    log_success "Apache2 esta iniciado"
fi

### Check if Apache2 is enabled
if ! systemctl is-enabled --quiet apache2; 
then
    log_info "Apache2 no esta activo. Activando Apache2..."
    systemctl enable apache2
else
    log_success "Apache2 esta activo."
fi

if [ -e "/var/www/html/index.html" ]; 
then
	mv /var/www/html/index.html /var/www/html/index.html.bkp
fi

systemctl reload apache2

##### Check if mariadb is running
if ! systemctl is-active --quiet mariadb; 
then
    log_info "Mariadb no esta iniciada. Iniciando mariadb..."
    systemctl start mariadb
else
    log_success "Mariadb esta iniciada"
fi

### Check if Mariadb is enabled
if ! systemctl is-enabled --quiet mariadb; 
then
    log_info "Mariadb no esta habilitada. Habilitando Mariadb..."
    systemctl enable mariadb
else
    log_success "Mariadb ya esta activa"
fi


log_info "Configurando base de datos ..."
### Configuaracio de database
echo -n "Set DB password:"
read DBPASS

mysql -e "
DROP DATABASE IF EXISTS devopstravel;
DROP USER IF EXISTS 'codeuser'@'localhost';
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY '$DBPASS';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"

# set pass db
OLDPASS='""'
sed -i "s~$OLDPASS~'"$DBPASS"'~g" /var/www/html/config.php

log_info "STAGE 1: [Init] ........complete"
### STAGE 2: [Build]
log_info "STAGE 2: [Build] ........starting"

# Clone or Update Project Repository
if [ -d "$REPO" ];
then
        log_info "Updating repository"
        cd $REPO
        git checkout clase2-linux-bash
        git pull
        cd ..
else
	log_info "Cloning Repository"
        git clone -b clase2-linux-bash $REPOURL$REPO
fi


mysql < ./$REPO/$FOLDER/database/devopstravel.sql

# copy Repository static files to Apache Folder
cp -r ./$REPO/$FOLDER/* /var/www/html/

# Check if the PHP configuration file exists
php_ini_path="/etc/php/8.2/apache2/php.ini"  # Adjust the path based on your system
if [ ! -e "$php_ini_path" ]; then
    log_error "Error: PHP configuration file not found at $php_ini_path. Please adjust the path in the script."
    exit 1
fi

# Add "index.php" to the list of default index files
if grep -q "^index.php" "$php_ini_path"; then
    log_warning "The PHP configuration already includes index.php."
else
    log_info #Adding index.php to the list of default index files in $php_ini_path."
    echo "DirectoryIndex index.php" | tee -a "$php_ini_path" > /dev/null
fi

# Restart Apache to apply the changes 
systemctl restart apache2
log_info "STAGE 2: [Build] ........Complete"
log_info "STAGE 3: [Deploy] ........Starting"

# Your application check logic here
ip_address=$(hostname -I)
WEB_URL=$ip_address/index.php
app_status=$(curl -Is $WEB_URL | head -n 1)
#app_status=$(curl -Is http://192.168.1.106/index.php | head -n 1)
app_status=$(echo "$app_status" | tr -d '\r')

# Check the application status and send a message to Discord


if [ "$app_status" == "HTTP/1.1 200 OK" ]; 
then
  # Obtén información del repositorio
    cd $REPO
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPOURL$REPO: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    TEAM="Team: Grupo 23"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi


log_info "STAGE 3: [Deploy] ........Complete"

log_info "STAGE 4: [Notify] ........Starting"

# Send message to Discord channel

# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION\n$TEAM"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"

log_info "STAGE 4: [Notify] ........Complete"

