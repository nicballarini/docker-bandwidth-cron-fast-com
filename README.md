
# Bandwidth Monitor with Docker and Cron

## Overview
This project runs a scheduled bandwidth test using [fast-cli](https://github.com/sindresorhus/fast-cli) inside a Docker container. The test is run once a week on Monday at 3 AM and logs the download/upload speeds to a file. The container utilizes `cron` to handle the scheduling, and the results are saved with the last 5 logs retained for analysis.

## Features
- Automated bandwidth tests every Monday at 3 AM (or customizable schedule).
- Logs download and upload speeds.
- Retains the last 5 logs for historical tracking.
- Uses Docker for easy deployment and isolation.
- Customizable cron schedule using Docker Compose.

## Prerequisites
- Docker must be installed on your machine.
- You need a basic understanding of Docker to build and run containers.

## How It Works
1. The Dockerfile installs necessary packages, including `fast-cli`, `cron`, and Google Chrome (for Puppeteer).
2. The main script, `speedtest.sh`, performs the bandwidth test and saves the results in `/usr/src/app/speedtest_logs`.
3. A cron job is set up in the Docker container to run the test based on a schedule defined by the `CRON_SCHEDULE` environment variable (defaults to Monday 3 AM).
4. The container keeps running, logging all `cron` activity to `/var/log/cron.log`.

## Build and Run

### Build the Docker Image
To build the Docker image, run the following command in the project directory:

```bash
docker build -t speedtest-scheduler .
```

### Run with Docker Compose
You can run the project using Docker Compose to customize the cron schedule:

1. Create a `docker-compose.yml` file in your project directory:

```yaml
---

services:
  speedtest-scheduler:
    build: .
    container_name: speedtest-scheduler
    environment:
      - CRON_SCHEDULE=0 3 * * 1   # Default cron schedule (3 AM every Monday), customize as needed
    #volumes:
    #  - ./logs:/var/log  # Optional: Mount logs for persistent storage
    restart: unless-stopped
```

2. Run the container:

```bash
docker-compose up -d
```

This will run the container in detached mode, with the cron job configured to the specified schedule.

### Check Logs
You can check the logs for the bandwidth tests using:

```bash
docker exec -it speedtest-scheduler cat /var/log/cron.log
```

To check individual bandwidth test logs:

```bash
docker exec -it speedtest-scheduler ls /tmp/fast.com_history_log
docker exec -it speedtest-scheduler cat /tmp/fast.com_history_log/fastlog_<timestamp>.log
```

## Manual Execution of the Speed Test

If you want to manually run the speed test without waiting for the cron job, you can execute the script directly inside the running container:

```bash
docker exec -it speedtest-scheduler /bin/bash /usr/src/app/speedtest.sh
```

## Customization

### Change the Cron Schedule
To change the schedule, modify the `CRON_SCHEDULE` in the `docker-compose.yml` file.

For example, to run the test daily at 6 AM, use:

```yaml
environment:
  - CRON_SCHEDULE=0 6 * * *
```

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- [fast-cli](https://github.com/sindresorhus/fast-cli)
- [Puppeteer](https://github.com/puppeteer/puppeteer)
