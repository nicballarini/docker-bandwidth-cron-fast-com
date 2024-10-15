#!/bin/bash

# Set variables
LOG_DIR="/usr/src/app/speedtest_logs"
MAX_LOG_FILES=5

# Create log directory if it doesn't exist
initialize_log_dir() {
    mkdir -p "$LOG_DIR"
}

# Calculate averages from the last $MAX_LOG_FILES runs
calculate_averages() {
    # Only calculate if we have enough logs
    if [ $(ls -1 "$LOG_DIR" | wc -l) -ge "$MAX_LOG_FILES" ]; then
        AVG_DOWN=$(cat "$LOG_DIR"/speedtest_* | cut -d' ' -f5 | tail -n $MAX_LOG_FILES | paste -sd+ | bc)
        AVG_UP=$(cat "$LOG_DIR"/speedtest_* | cut -d' ' -f9 | tail -n $MAX_LOG_FILES | paste -sd+ | bc)

        # Divide to get the average speeds
        AVG_DOWN=$(echo "$AVG_DOWN / $MAX_LOG_FILES" | bc)
        AVG_UP=$(echo "$AVG_UP / $MAX_LOG_FILES" | bc)

        echo "Average Download speed (last $MAX_LOG_FILES runs): $AVG_DOWN Mbps"
        echo "Average Upload speed (last $MAX_LOG_FILES runs): $AVG_UP Mbps"
    else
        echo "Not enough data to calculate averages (less than $MAX_LOG_FILES logs)."
    fi
}

# Run the speed test and log the output
run_speed_test() {
    LOG_FILE="$LOG_DIR/speedtest_$(date +%Y%m%d_%H%M%S).log"
    echo "Running Bandwidth test..."
    /usr/local/bin/fast --upload --single-line | tail -n 1 > "$LOG_FILE"

    if [ $? -ne 0 ]; then
        echo "Bandwidth test failed."
        exit 1
    fi

    echo "Bandwidth test finished."
    cat "$LOG_FILE"

    # Extract download and upload speeds from the latest log
    DOWN=$(cat "$LOG_FILE" | cut -d' ' -f5)
    UP=$(cat "$LOG_FILE" | cut -d' ' -f9)

    echo "Download: $DOWN Mbps, Upload: $UP Mbps"
}

# Retain only the last $MAX_LOG_FILES logs and truncate cron.log to 20 lines
manage_logs() {
    LOG_COUNT=$(ls -1t "$LOG_DIR" | wc -l)
    if [ "$LOG_COUNT" -gt "$MAX_LOG_FILES" ]; then
        ls -1t "$LOG_DIR" | tail -n +$((MAX_LOG_FILES + 1)) | xargs -I {} rm "$LOG_DIR/{}"
    fi

    # Truncate cron.log to the last 20 lines
    tail -n 20 /usr/src/app/cron.log > /usr/src/app/cron.log.tmp && mv /usr/src/app/cron.log.tmp /usr/src/app/cron.log
}

# Main function to execute the full process
main() {
    initialize_log_dir
    calculate_averages     # Calculate averages from the existing logs before the new test
    run_speed_test          # Run the new speed test and log the results
    manage_logs             # Clean up old logs to maintain a max of $MAX_LOG_FILES
}

# Execute the main function
main
