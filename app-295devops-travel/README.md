# **Ejercicio-1 Linux y Automatización**
## **Objetivos**
El objetivo del ejercicio 1 radica en la automatización mediante un script bash de los pasos manuales que se ejecutarían en una consola Linux para la instalación del sistema **app-295devops-travel.**

El script en bash debe implementar una arquitectura LAMP sobre la que fue desarrollado la aplicación permitiendo instalar un servidor web (Apache), una base de datos (MariaDB) y el lenguaje PHP que contiene la lógica de la aplicación web
## **Arquitectura**
En el diagrama de arquitectura, los usuarios inician una solicitud HTTP accediendo a la aplicación a través del navegador utilizando "localhost" o la dirección IP del servidor. El servidor, con Apache instalado, responde entregando el archivo a los usuarios, solicitándoles que completen sus datos, incluido su nombre, correo electrónico y descripción.

Al completar el formulario, los usuarios envían los datos al servidor. Luego, Apache reenvía los datos enviados a un script PHP responsable de almacenar esta información en la base de datos MySQL. Si los datos se almacenan correctamente, MySQL comunica este éxito al script PHP, que responde con un mensaje HTML que se muestra en el navegador del usuario. Por otro lado, si hay un problema al guardar los datos, el script PHP devuelve un mensaje de error al navegador del usuario, notificándole el problema encontrado

![Alt Text](Aspose.Words.208a4e9b-c58e-4011-955a-66c7bfa7ff34.001.png)

## **Implementación**
La implementación del script de instalación deberá considerar las siguientes etapas:

### STAGE 1: [Init]

1. Instalacion de paquetes en el sistema operativo ubuntu: [apache2 git curl php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl mariadb-server]
1. Validación si esta instalado los paquetes o no , de manera de no reinstalar
1. Habilitar y Testear instalación de los paquetes

### STAGE 2: [Build]

1. Clonar el repositorio de la aplicación
1. Validar si el repositorio de la aplicación no existe realizar un git clone. y si existe un git pull
1. Mover al directorio donde se guardar los archivos de configuración de apache /var/www/html/
1. Testear existencia del codigo de la aplicación
1. Ajustar el config de php para que soporte los archivos dinamicos de php agregando index.php
1. Testear la compatibilidad -> ejemplo <http://localhost/info.php>

### STAGE 3: [Deploy]

1. Hacer un reload de apache y acceder a la aplicacion DevOps Travel
1. Verificar si Aplicación esta disponible para el usuario final.

### STAGE 4: [Notify]

1. El status de la aplicacion si esta respondiendo correctamente o está fallando debe reportarse via webhook al canal de discord #deploy-bootcamp
1. Informacion a mostrar : Author del Commit, Commit, descripcion, grupo y status

## **Instalación**
La instalación del aplicativo deberá realizarse sobre un sistema Linux (Ubuntu preferentemente) siguiendo estos pasos:

1) Connectarse como usuario root al equipo Linux donde se desea instalar el aplicativo
1) Acceder un directorio de proyecto donde se ejecutara el script
1) Crear un directorio de trabajo llamado bootcamp
1) Clonar repositorio informado dentro de directorio de trabajo bootcamp
1) Copiar archivo ./app-295devops-travel/deploy01.sh al directorio de proyecto  donde se ejecutara el script (paso 2)
1) Verificar que el script deploy01.sh disponga de permisos de ejecución
1) Ejecutar el script de instalacion

## **Contribuciones**

### **Equipo 23**

1. Hector Sola Garrido

