# Tarea-2-
Esta tarea implementa un entorno de laboratorio aislado para el estudio, generación y análisis de tráfico de red utilizando el protocolo abierto de mensajería instantánea **XMPP (Extensible Messaging and Presence Protocol)**. La arquitectura se despliega de forma manual mediante contenedores independientes para el cliente y el servidor, permitiendo la captura de tramas en tiempo real sin el uso de herramientas de orquestación como Docker Compose.

---

## Arquitectura del Entorno

La solución se compone de tres elementos modulares interconectados en una red puente (*bridge*) privada:

1. **Red Virtual (`red-xmpp`):** Canal de comunicación aislado que facilita la resolución de nombres de dominio interna entre los contenedores.
2. **Servidor XMPP (`ejabberd`):** Servidor de mensajería empresarial corriendo la imagen oficial de Docker, configurado con el host virtual `localhost`.
3. **Cliente XMPP (`Profanity`):** Cliente interactivo basado en consola de comandos, contenedorizado desde cero con una imagen personalizada de Ubuntu 22.04 LTS.

---

## Paso a Paso

Sigue estos comandos de forma secuencial en la terminal para levantar el laboratorio completo:

 1. Inicialización de la Infraestructura de Red
Crea la red virtual bridge para permitir que el cliente y el servidor se comuniquen:

'docker network create red-xmpp'

2. Construcción del Cliente Personalizado (Profanity)

Ubícate dentro del directorio que contiene el código fuente de Profanity y el Dockerfile, y construye la imagen:

'docker build --no-cache -t taller-redes-profanity .'

3. Despliegue del Servidor (ejabberd)

Descarga e inicia el contenedor del servidor oficial configurando las credenciales administrativas y el dominio local:

'docker run --name mi-servidor-xmpp \
  --network red-xmpp \
  -d \
  -p 5222:5222 \
  -p 5269:5269 \
  -p 5280:5280 \
  -e EJABBERD_ADMIN_USER="admin" \
  -e EJABBERD_ADMIN_PASSWORD="password123" \
  -e EJABBERD_HOSTS="localhost" \
  ejabberd/ecs'

4. Aprovisionamiento de Usuarios de Prueba

Espera unos 10 segundos a que el servidor inicialice sus servicios y registra las dos identidades necesarias para interactuar:

'docker exec -it mi-servidor-xmpp ejabberdctl register user1 localhost clave123'
'docker exec -it mi-servidor-xmpp ejabberdctl register user2 localhost clave123'

Para generar tráfico legible y analizar el protocolo, simula una arquitectura concurrente abriendo dos pestañas en tu terminal física:

Pestaña 1: Sesión del Usuario Principal (user1)

    Instancia el primer cliente en la red:

    docker run -it --name mi-cliente-xmpp --network red-xmpp taller-redes-profanity

    Una vez dentro de la interfaz de Profanity, conéctate al servidor forzando el uso seguro de TLS:

    /connect user1@localhost server mi-servidor-xmpp tls allow

    (Ingresa la contraseña clave123 cuando sea solicitada).

Pestaña 2: Sesión del Usuario Secundario (user2)

    Instancia un segundo contenedor en paralelo:
    Bash

    docker run -it --name cliente2 --network red-xmpp taller-redes-profanity

    Conéctate utilizando la segunda identidad registrada:

    /connect user2@localhost server mi-servidor-xmpp tls allow

Vinculación e Interacción

Dentro de la consola de user1, añade al usuario secundario a tu lista de contactos (Roster) y envíale un mensaje:

/roster add user1@localhost
/msg user1@localhost "Hola, esto es una prueba de tráfico XMPP segura con TLSv1.3"

Captura de Tráfico con Wireshark

Para capturar los paquetes de red legítimos generados por el contenedor:

    Identifica el identificador hexadecimal único de la red interna de Docker:
    Bash

    docker network inspect red-xmpp --format '{{.Id}}'

    Toma los primeros 12 caracteres del resultado (ej. b50e41aec838) y localiza la interfaz equivalente en tu sistema operativo: br-b50e41aec838.

    Abre Wireshark con privilegios de administrador para permitir la escucha promiscua en interfaces virtuales:

    sudo wireshark

    Selecciona la tarjeta de red br-X correspondiente y aplica el filtro de visualización xmpp o tcp.port == 5222.

Persistencia de Contenedores (Próximos Inicios)

Para reanudar usa los siguientes comandos:

    Encender Servidor: docker start mi-servidor-xmpp

    Abrir Cliente 1: docker start -ai mi-cliente-xmpp

    Abrir Cliente 2: docker start -ai cliente2
