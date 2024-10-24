#!/bin/bash

git pull

# Obtiene la dirección IP privada de la Mac
HOST_IP=$(ifconfig en0 | grep 'inet ' | awk '{print $2}')

# Verifica si se obtuvo la IP correctamente
if [ -z "$HOST_IP" ]; then
    echo "No se pudo obtener la dirección IP."
fi

echo "Running in $HOST_IP"

docker stop local-sanji
sleep 5
docker rm local-sanji
sleep 5

docker image prune -a -f --filter "until=730h"

docker pull sanjidev/gateway:latest

# Ejecuta el comando docker run con la variable de entorno
docker run --pull always --platform linux/amd64 -e HOST_PRIVATE_IP=$HOST_IP -p 3000:3000 -v ./volumes/pg:/home/nextjs/postgresql/data -w /home/nextjs/postgresql/data --name local-sanji --rm sanjidev/gateway:latest || docker run --platform linux/amd64 -e HOST_PRIVATE_IP=$HOST_IP -p 3000:3000 -v ./volumes/pg:/home/nextjs/postgresql/data -w /home/nextjs/postgresql/data --name local-sanji --rm sanjidev/gateway:latest
