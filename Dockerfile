FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar herramientas de compilación tanto para Meson como para Autotools (requerido por subproyectos)
RUN apt-get update && apt-get install -y \
    meson \
    ninja-build \
    pkg-config \
    libtool \
    autoconf \
    automake \
    autoconf-archive \
    libglib2.0-dev \
    libreadline-dev \
    libncursesw5-dev \
    libcurl4-openssl-dev \
    libexpat1-dev \
    libssl-dev \
    uuid-dev \
    libgpgme-dev \
    libotr5-dev \
    libsignal-protocol-c-dev \
    libgcrypt20-dev \
    libsqlite3-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Definir el directorio de trabajo
WORKDIR /app

# Copiar los archivos locales al contenedor
COPY . .

# Descargar las dependencias faltantes automáticamente y compilar
RUN meson setup build --wrap-mode=forcefallback && ninja -C build install

# Comando por defecto para iniciar la aplicación
CMD ["profanity"]
