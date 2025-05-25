#!/bin/bash
# Path to the root directory containing WordPress sites
BASE_DIR="/home"

# Check if the base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: Directory $BASE_DIR does not exist."
    exit 1
fi

# Loop through each user directory in /home/
for user_dir in "$BASE_DIR"/*/ ; do
    # Check if public_html exists in the user directory
    wp_config="${user_dir}public_html/wp-config.php"
    
    if [[ -f "$wp_config" ]]; then
        # Extract the domain (or directory name) for clarity
        domain=$(basename "$user_dir")
        echo "Processing domain: $domain"
        
        # Try multiple patterns to extract DB_NAME
        db_name=""
        
        # Pattern 1: Standard single quotes with various spacing
        if [[ -z "$db_name" ]]; then
            db_name=$(grep -i "define.*DB_NAME" "$wp_config" | sed -n "s/.*define[[:space:]]*([[:space:]]*['\"]DB_NAME['\"][[:space:]]*,[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p" | head -1)
        fi
        
        # Pattern 2: Using awk for more robust parsing
        if [[ -z "$db_name" ]]; then
            db_name=$(awk -F"'" '/define.*DB_NAME/ {print $4}' "$wp_config" | head -1)
        fi
        
        # Pattern 3: Using sed with a simpler approach
        if [[ -z "$db_name" ]]; then
            db_name=$(grep -i "DB_NAME" "$wp_config" | sed "s/.*['\"]\\([^'\"]*\\)['\"].*/\\1/" | grep -v "DB_NAME" | head -1)
        fi
        
        # Pattern 4: Handle double quotes
        if [[ -z "$db_name" ]]; then
            db_name=$(grep -i "define.*DB_NAME" "$wp_config" | grep -oP "define\s*\(\s*[\"']DB_NAME[\"']\s*,\s*[\"']\K[^\"']+")
        fi
        
        if [[ -n "$db_name" ]]; then
            echo "  Database Name: $db_name"
        else
            echo "  Error: Could not find DB_NAME in $wp_config"
            echo "  Debug: Showing DB_NAME line from wp-config.php:"
            grep -i "DB_NAME" "$wp_config" || echo "  No DB_NAME line found"
        fi
    else
        echo "Skipping $user_dir: wp-config.php not found"
    fi
done

echo "Done processing all WordPress sites."
