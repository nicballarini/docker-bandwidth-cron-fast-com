#!/bin/bash

LOG_DIR="/tmp/fast.com_history_log"
MAX_LOG_FILES=5

# create the log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# function to clean up old logs and keep only the last 5
cleanup_logs() {
    log_count=$(ls "$LOG_DIR" | wc -l)
    if (( log_count > MAX_LOG_FILES )); then
        ls -t "$LOG_DIR" | tail -n +$((MAX_LOG_FILES+1)) | xargs -I {} rm "$LOG_DIR/{}"
    fi
}

# function to log and extract values from the bandwidth test
run_bandwidth_test() {
    echo "Running Bandwidth test..."

    # generate a descriptive log file name with timestamp
    LOG_FILE="$LOG_DIR/fastlog_$(date +'%Y-%m-%d_%H-%M-%S').log"

    # run the test, store the result directly in a variable
    result=$(/usr/src/app/node_modules/.bin/fast --upload --single-line | tail -n 1)

    # check if the test returned a valid result
    if [[ -z "$result" ]]; then
        echo "Bandwidth test failed."
        return 1
    fi

    # log the result to the descriptive file
    echo "$result" > "$LOG_FILE"
    echo "Bandwidth test finished."
    cat "$LOG_FILE"

    # extract download and upload speeds
    DOWN=$(echo "$result" | cut -d' ' -f5)
    UP=$(echo "$result" | cut -d' ' -f9)

    echo "Current Download speed: $DOWN Mbps"
    echo "Current Upload speed: $UP Mbps"
}

# function to calculate and print the average download/upload speeds
calculate_average_speeds() {
    total_down=0
    total_up=0
    file_count=0

    for file in "$LOG_DIR"/*; do
        down=$(cat "$file" | cut -d' ' -f5)
        up=$(cat "$file" | cut -d' ' -f9)

        total_down=$(echo "$total_down + $down" | bc)
        total_up=$(echo "$total_up + $up" | bc)
        file_count=$((file_count + 1))
    done

    if (( file_count > 0 )); then
        avg_down=$(echo "scale=2; $total_down / $file_count" | bc)
        avg_up=$(echo "scale=2; $total_up / $file_count" | bc)
        echo "Average Download speed (last $file_count runs): $avg_down Mbps"
        echo "Average Upload speed (last $file_count runs): $avg_up Mbps"
    fi
}

run_bandwidth_test
cleanup_logs
calculate_average_speeds
