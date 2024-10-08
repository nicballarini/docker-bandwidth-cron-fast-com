# Use an official Node.js runtime as a parent image
FROM node:18-buster-slim

WORKDIR /usr/src/app

# Install required packages (cron, wget, gnupg)
RUN apt update && apt install -y cron wget gnupg bc

# Install Google Chrome and dependencies for Puppeteer
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google.list \
    && apt update && apt install -y google-chrome-stable libxss1 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install Puppeteer and fast-cli globally
RUN npm install puppeteer fast-cli --legacy-peer-deps --global

# Create a non-root user for Puppeteer to run as
RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser

# Copy the speedtest script to the working directory
COPY speedtest.sh /usr/src/app/speedtest.sh

# Set environment variable for CRON_SCHEDULE, defaulting to Monday 3 AM if not provided
ENV CRON_SCHEDULE="0 3 * * 1"

# Set up cron job using the CRON_SCHEDULE environment variable
RUN echo "$CRON_SCHEDULE /bin/bash /usr/src/app/speedtest.sh >> /usr/src/app/cron.log 2>&1" > /etc/cron.d/speedtest-cron

# Give execution rights on the cron job and script
RUN chmod 0644 /etc/cron.d/speedtest-cron && chmod +x /usr/src/app/speedtest.sh

# Apply the cron job
RUN crontab /etc/cron.d/speedtest-cron

# Ensure correct ownership for Puppeteer's node_modules and setup directories
RUN mkdir -p /node_modules && chown -R pptruser:pptruser /node_modules

# Create the log file to be able to run tail
RUN touch /usr/src/app/cron.log

# Set the entrypoint to start cron in the background and tail the log file to keep the container running
CMD cron && tail -f /usr/src/app/cron.log
