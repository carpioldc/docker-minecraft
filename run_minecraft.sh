#! /bin/bash
image=minecraft-client:1.4

echo_color() {
    green=`tput setaf 2`
    reset=`tput sgr0`
    echo "${green}$*${reset}"
}

minecraft_download() {
    echo_color Downloading Minecraft
    wget https://launcher.mojang.com/download/Minecraft.tar.gz
}

minecraft_decompress() {
    echo_color Decompressing Minecraft
    tar -xzf Minecraft.tar.gz
}

container_build() {
    echo_color Building Docker image
    cat << EOF |
FROM fedora:31
RUN dnf install -y \
      java-1.8.0-openjdk \
      strace \
      gtk3 \
      nss-tools \
      libX11-xcb \
      libXScrnSaver \
      GConf2 \
      libglvnd-glx \
      PackageKit-gtk3-module \
      libcanberra-gtk3 \
      mesa-dri-drivers
EOF
    docker build -t $image -f - .
}

container_run() {
    echo_color Running container
    docker run -ti \
        -e DISPLAY \
        -v $(pwd)/minecraft-launcher:/opt/minecraft \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v $HOME/.minecraft:/root/.minecraft:rw \
        -v $HOME/.Xauthority:/root/.Xauthority \
        --net=host \
        --cap-add=ALL \
        --device=/dev/dri:/dev/dri \
        --rm \
        $image \
        bash -c "/opt/minecraft/minecraft-launcher 2>/dev/null; /opt/minecraft/minecraft-launcher"
}

main() {
    # Download Minecraft release
    if [ ! -f ./Minecraft.tar.gz ]; then
        minecraft_download
    fi
    # Decompress release
    if [ ! -d ./minecraft-launcher ]; then
        minecraft_decompress || (rm Minecraft.tar.gz && minecraft_download)
    fi
    # Build docker image
    if ! [ $(docker images $image | wc -l) -gt 1 ]; then
        container_build
    fi

    container_run
}

main
