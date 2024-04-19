#!/bin/bash

# Function to convert CPU percentage to time units (seconds)
cpu_percentage_to_seconds() {
    local pid=$1
    local utime=$(awk '{print $14}' /proc/$pid/stat 2>/dev/null)
    local stime=$(awk '{print $15}' /proc/$pid/stat 2>/dev/null)
    if [[ -n "$utime" && -n "$stime" ]]; then
        local total_time=$((utime + stime))
        local hertz=$(getconf CLK_TCK)
        local seconds=$((total_time / hertz))
        echo "$seconds"
    else
        echo "0"  # Return 0 if unable to retrieve CPU time
    fi
}

# Get list of all users with running processes
users=$(ps -eo user= | sort | uniq)

# Initialize arrays to store CPU time, memory usage, and file count per user
declare -A cpu_usage
declare -A memory_usage
declare -A file_count

# Iterate over each user
for user in $users; do
    # Get list of PIDs for processes owned by the user
    pids=$(ps -u $user -o pid=)

    # Initialize counters
    total_cpu=0
    total_memory=0
    total_files=0

    # Iterate over each PID
    for pid in $pids; do
        # Check if PID still exists
        if [ -d "/proc/$pid" ]; then
            # Calculate CPU time in seconds
            cpu_seconds=$(cpu_percentage_to_seconds $pid)

            # Accumulate CPU time
            total_cpu=$((total_cpu + cpu_seconds))

            # Get memory usage in MB
            mem_usage=$(pmap -x $pid | tail -n 1 | awk '{print $3}')
            total_memory=$(awk "BEGIN {print $total_memory + $mem_usage}")

            # Get file count
            file_count=$(ls -l /proc/$pid/fd 2>/dev/null | grep -c '^l')
            total_files=$((total_files + file_count))
        fi
    done

    # Store aggregated data for the user
    cpu_usage[$user]=$total_cpu
    memory_usage[$user]=$total_memory
    file_count[$user]=$total_files
done

# Print report sorted by CPU usage
echo "============================================================================="
echo "| User            | CPU Time (Milliseconds) | Memory Usage (MB) | File Count |"
echo "============================================================================="
for user in "${!cpu_usage[@]}"; do
    printf "| %-15s | %23d | %17d | %10d |\n" "$user" "${cpu_usage[$user]}" "${memory_usage[$user]}" "${file_count[$user]}"
done | sort -rnk2
echo "============================================================================="
