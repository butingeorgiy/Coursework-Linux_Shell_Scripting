#!/bin/bash

# Function to count files with specific permissions for a given user
count_files() {
    local user=$1
    local setuid=$(find / -type f -user "$user" -perm -4000 2>/dev/null | wc -l)
    local setgid=$(find / -type f -group "$user" -perm -2000 2>/dev/null | wc -l)
    local world_writable=$(find / -type f -user "$user" -perm -o+w 2>/dev/null | wc -l)
    local unowned=$(find / -type f ! -user "$user" -exec stat -c "%U" {} + 2>/dev/null | grep "^$" | wc -l)
    
    printf "| %-15s | %6d | %6d | %13d | %7d |\n" "$user" "$setuid" "$setgid" "$world_writable" "$unowned"
}

# Get list of all users
users=$(getent passwd | cut -d: -f1)

# Print header
echo "======================================================================="
echo "| User            | Setuid | Setgid | World_Writable | Unowned Files |"
echo "======================================================================="

# Iterate over each user
for user in $users; do
    count_files $user
done | sort -rnk2 -k3 -k4

echo "======================================================================="
