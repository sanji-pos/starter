@echo off
setlocal EnableDelayedExpansion

git reset --hard HEAD

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

    :: Validate the last 2 digits of the IP address
    set last_two_chars=!temp_ip:~-2!
    if not "!last_two_chars!"==".1" (
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

:: Initialize retry attempt for docker run command
set docker_run_attempts=0
set max_docker_run_attempts=3
set use_pull_flag=true

:runDockerContainer
if "!use_pull_flag!"=="true" (
    docker run --pull always -d -u nextjs --platform linux/amd64 -e HOST_PRIVATE_IP=!ip! -p 3000:3000 -v "kosmodb:/home/nextjs/database" -w /home/nextjs/database --name local-sanji --rm sanjidev/gateway:latest
) else (
    docker run -d -u nextjs --platform linux/amd64 -e HOST_PRIVATE_IP=!ip! -p 3000:3000 -v "kosmodb:/home/nextjs/database" -w /home/nextjs/database --name local-sanji --rm sanjidev/gateway:latest
)

if errorlevel 1 (
    echo Docker run failed. Retrying...
    set /a docker_run_attempts+=1
    if %docker_run_attempts% geq %max_docker_run_attempts% (
        echo Docker run failed after %max_docker_run_attempts% attempts. Exiting.
        exit /b 1
    )
    :: Remove the --pull always flag for the next attempt
    set use_pull_flag=false
    timeout /t 5 >nul
    goto runDockerContainer
)

echo Docker container is running successfully.

endlocal
