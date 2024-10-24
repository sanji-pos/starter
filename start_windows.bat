@echo off
setlocal EnableDelayedExpansion

:: Initialize attempt counter
set attempts=0
set max_attempts=10

:: Wait for Docker to be ready
:waitForDocker
docker info >nul 2>&1
if errorlevel 1 (
    echo Waiting for Docker daemon to be ready...
    set /a attempts+=1
    if %attempts% geq %max_attempts% (
        echo Docker daemon did not start after %max_attempts% attempts. Exiting.
        exit /b 1
    )
    goto waitForDocker
)

:: Check and create volumes/pg directory if it doesn't exist
if not exist "volumes\pg" (
    mkdir "volumes"
    mkdir "volumes\pg"
)

:: Get all IPv4 Addresses and find the first one that does not end with '1'
set "ip="
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4"') do (
    set temp_ip=%%A
    set temp_ip=!temp_ip:~1!

    :: Validate the last digit of the IP address
    set last_digit=!temp_ip:~-1!
    if not "!last_digit!"=="1" (
        set "ip=!temp_ip!"
        goto found_ip
    )
)

:found_ip
if defined ip (
    echo Setting HOST_PRIVATE_IP to !ip!
) else (
    echo No valid IP address found. Exiting.
    exit /b 1
)

:: Pull the latest changes from the git repository
git pull

echo Running in !ip!

:: Stop and remove the existing Docker container
docker stop local-sanji
timeout 5
docker rm local-sanji
timeout 5

docker volume create kosmodb

:: Prune unused images
docker image prune -a -f --filter "until=730h"

:: Pull the latest Docker image
docker pull sanjidev/gateway:latest

:: Run the Docker container
docker run --pull always -d -u nextjs --platform linux/amd64 -e HOST_PRIVATE_IP=!ip! -p 3000:3000 -v "kosmodb:/home/nextjs/postgresql/data" -w /home/nextjs/postgresql/data --name local-sanji --rm sanjidev/gateway:latest

endlocal
