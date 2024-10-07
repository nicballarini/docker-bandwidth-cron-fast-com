FROM node:18-buster-slim

# install required packages
RUN apt update && apt install -y cron wget gnupg

# install Google Chrome, Puppeteer, and fast-cli
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list.d/google.list \
    && apt update && apt install -y google-chrome-stable libxss1 --no-install-recommends \
    && npm install puppeteer fast-cli --legacy-peer-deps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# copy the script to the container
COPY speedtest.sh /usr/src/app/speedtest.sh

# add a cron job to run every Monday at 3 AM
RUN echo "0 3 * * 1 /bin/bash /usr/src/app/speedtest.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/bandwidth-cron

# give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/bandwidth-cron

# apply the cron job
RUN crontab /etc/cron.d/bandwidth-cron

# create the log file to be able to run tail
RUN touch /var/log/cron.log

# start cron and then tail the log file
CMD cron && tail -f /var/log/cron.log
