update_md_file() {
    local md_file=$1
    local app_name=$2
    local project_name=$3
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Initialize state variables
    in_section=""
    
    while IFS= read -r line; do
        # Check for main list items we're interested in
        if [ "$line" = "8. Proposed Account 1" ]; then
            in_section="account1"
            echo "$line" >> "$temp_file"
        elif [ "$line" = "9. Proposed Account 2" ]; then
            in_section="account2"
            echo "$line" >> "$temp_file"
        elif [ "$line" = "11. Proposed Account Alias" ]; then
            in_section="alias"
            echo "$line" >> "$temp_file"
        elif [ "$line" = "14. Group Descriptor" ]; then
            in_section="descriptor"
            echo "$line" >> "$temp_file"
        # Handle nested list items based on current section
        elif [ "$in_section" != "" ] && [[ $line =~ ^[[:space:]]*[0-9]+\. ]]; then
            case $in_section in
                "account1")
                    if [ "$line" = "   1. Default Account 1" ]; then
                        echo "   1. ${app_name}${project_name}SNFR1" >> "$temp_file"
                    elif [ "$line" = "   2. Default Account 2" ]; then
                        echo "   2. ${app_name}${project_name}SNFP1" >> "$temp_file"
                    elif [ "$line" = "   3. Default Account 3" ]; then
                        echo "   3. ${app_name}${project_name}SNFQ1" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
                "account2")
                    if [ "$line" = "   1. Default Account 1" ]; then
                        echo "   1. ${app_name}${project_name}SNFR2" >> "$temp_file"
                    elif [ "$line" = "   2. Default Account 2" ]; then
                        echo "   2. ${app_name}${project_name}SNFP2" >> "$temp_file"
                    elif [ "$line" = "   3. Default Account 3" ]; then
                        echo "   3. ${app_name}${project_name}SNFQ2" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
                "alias")
                    if [ "$line" = "   1. Default Alias 1" ]; then
                        echo "   1. domino-ENT-${project_name,,}-small-batch-SNFR" >> "$temp_file"
                    elif [ "$line" = "   2. Default Alias 2" ]; then
                        echo "   2. domino-ENT-${project_name,,}-small-batch-SNFP" >> "$temp_file"
                    elif [ "$line" = "   3. Default Alias 3" ]; then
                        echo "   3. domino-ENT-${project_name,,}-small-batch-SNFQ" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
                "descriptor")
                    local clean_project=$(echo "$project_name" | tr -d '-')
                    local clean_app=$(echo "$app_name" | tr -d '-')
                    if [ "$line" = "   1. Default Descriptor 1" ]; then
                        echo "   1. ${clean_app}${clean_project}READ" >> "$temp_file"
                    elif [ "$line" = "   2. Default Descriptor 2" ]; then
                        echo "   2. ${clean_app}${clean_project}P" >> "$temp_file"
                    elif [ "$line" = "   3. Default Descriptor 3" ]; then
                        echo "   3. ${clean_app}${clean_project}Q" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
            esac
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$md_file"
    
    # Replace original file with modified content
    mv "$temp_file" "$md_file"
}