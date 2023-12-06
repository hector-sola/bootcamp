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
CONFIG_APACHE="/etc/apache2/mods-enabled/dir.conf"
CONFIG_PHP="/var/www/html/config.php"


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


validar_root () {
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
}

update_packagelist () {

	log_info "Actualizando package list de Ubuntu"
	apt-get update -y

	# Check the exit code of the apt-get update command. $?: This special variable holds the exit code of the last command
	if [ $? -eq 0 ]; then
    	  log_success "Package List actualizado"
	else
          log_error "Error: apt-get update failed. Please check your internet connection or repository configuration."
    	  exit 1  # Exit the script with an error code
	fi
}

install_services_packages () {
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
}

checkApache () {
	if ! systemctl is-active --quiet apache2; 
	then
	    log_info "Apache2 no iniciado. Iniciando Apache2..."
	    systemctl start apache2
	else
	    log_success "Apache2 esta iniciado"
	fi
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
}

checkMariaDB () {
	if ! systemctl is-active --quiet mariadb; 
	then
	    log_info "Mariadb no esta iniciada. Iniciando mariadb..."
	    systemctl start mariadb
	else
	    log_success "Mariadb esta iniciada"
	fi
	if ! systemctl is-enabled --quiet mariadb; 
	then
	    log_info "Mariadb no esta habilitada. Habilitando Mariadb..."
	    systemctl enable mariadb
	else
	    log_success "Mariadb ya esta activa"
	fi
}


clonarRepo () {
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
}
ConfiguracionApache() {
  log_info "Validación de PHP."
  php -v
  if [ -f "$CONFIG_APACHE" ]; then
    sed -i 's/DirectoryIndex.*/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' "$CONFIG_APACHE"
    log_info "Se ha actualizado el orden en el archivo $CONFIG_APACHE"
    systemctl reload apache2
  else
    log_error "El archivo $CONFIG_APACHE no existe."
  fi
}
ConfigPHP() {
  # copy Repository static files to Apache Folder
  cp -r ./$REPO/$FOLDER/* /var/www/html/
  if [ -f "$CONFIG_PHP" ]; then
    #sed -i 's/$dbPassword = "";/&\n$dbPassword = "coder";/' "$CONFIG_PHP"
    sed -i "s/\"\";/\"$DBPASS\";/" "$CONFIG_PHP"
    log_info "La contraseña de la base de datos fue insertada en $CONFIG_PHP" 
    sudo systemctl reload apache2
  else
    log_error "El archivo $CONFIG_PHP no existe. Por favor validar."
    exit 
  fi
}

ConfiguracionDB() {
      log_info "Configurando base de datos ..."
      mysql -e "
      DROP DATABASE IF EXISTS devopstravel;
      DROP USER IF EXISTS 'codeuser'@'localhost';
      CREATE DATABASE devopstravel;
      CREATE USER 'codeuser'@'localhost' IDENTIFIED BY '$DBPASS';
      GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
      FLUSH PRIVILEGES;"
      mysql < ./$REPO/$FOLDER/database/devopstravel.sql
}


### STAGE 1: [Init]
log_info "STAGE 1: [Init] ........starting"

### Comprobacion de usuario root para ejecutar el script de deploy
validar_root

### Update the package list
update_packagelist

### Installing packages required if need it
log_info "Actualiazando paquetes requeridos"
install_services_packages

##### Check if Apache2 is running and enable
checkApache

##### Check if MariaDB is running and enable
checkMariaDB

### Configuaracio de database
log_info "Configurando base de datos ..."
echo -n "Set DB password:"
read DBPASS

log_info "STAGE 1: [Init] ........complete"
### STAGE 2: [Build]
log_info "STAGE 2: [Build] ........starting"

# Clone or Update Project Repository
clonarRepo

#Configuración del servicio Apache2
ConfiguracionApache

#Configuración PHP
ConfigPHP

#Configuración de la base de datos
ConfiguracionDB

log_info "STAGE 2: [Build] ........Complete"

log_info "STAGE 3: [Deploy] ........Starting"

# Your application check logic here
ip_address=$(hostname -I)
WEB_URL=$ip_address/index.php
app_status=$(curl -Is $WEB_URL | head -n 1)

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

#apt list libapache2-mod-php*
