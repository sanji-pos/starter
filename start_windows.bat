@echo off
setlocal

:: Start Docker Desktop
start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

:: Wait for Docker to start (adjust the timeout as needed)
timeout 60

:: Check and create volumes/pg directory if it doesn't exist
if not exist "volumes\pg" (
    mkdir "volumes"
    mkdir "volumes\pg"
)

:: Get the IPv4 Address
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4"') do (
    set ip=%%A
)

:: Trim leading spaces from IP address
set ip=%ip:~1%

:: Pull the latest changes from the git repository
git pull

echo Running in %ip%

:: Stop and remove the existing Docker container
docker stop local-sanji
timeout 5
docker rm local-sanji
timeout 5

:: Prune unused images
docker image prune -a -f --filter "until=730h"

:: Pull the latest Docker image
docker pull sanjidev/gateway:latest

:: Run the Docker container
docker run -u nextjs --platform linux/amd64 -e HOST_PRIVATE_IP=%ip% -p 3000:3000 -v "%cd%\volumes\pg:/var/lib/postgresql/data" -w /var/lib/postgresql/data --name local-sanji --rm sanjidev/gateway:latest

endlocal
