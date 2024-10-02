@echo off
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr "Dirección IPv4"') do (
    set ip=%%A
)

git pull

echo Running in %ip:~1%

docker stop local-sanji
timeout 5

docker rm local-sanji
timeout 5

docker image prune -a -f --filter "until=730h"

docker pull sanjidev/gateway:latest

docker run -u nextjs --platform linux/amd64 -e HOST_PRIVATE_IP=%ip:~1% -p 3000:3000 -v C:\Sanji:/var/lib/postgresql/data -w /var/lib/postgresql/data --name local-sanji --rm sanjidev/gateway:latest

pause
