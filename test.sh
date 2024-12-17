update_md_file() {
    local md_file=$1
    local app_name=$2
    local project_name=$3
    
    # Create a temporary file
    temp_file=$(mktemp)
    
    # Initialize state variables
    in_section=false
    current_section=""
    
    while IFS= read -r line < "$md_file"; do
        # Check for main list items we're interested in
        if [[ $line =~ ^[[:space:]]*8\.[[:space:]]Proposed[[:space:]]Account[[:space:]]1 ]]; then
            in_section="account1"
            echo "$line" >> "$temp_file"
        elif [[ $line =~ ^[[:space:]]*9\.[[:space:]]Proposed[[:space:]]Account[[:space:]]2 ]]; then
            in_section="account2"
            echo "$line" >> "$temp_file"
        elif [[ $line =~ ^[[:space:]]*11\.[[:space:]]Proposed[[:space:]]Account[[:space:]]Alias ]]; then
            in_section="alias"
            echo "$line" >> "$temp_file"
        elif [[ $line =~ ^[[:space:]]*14\.[[:space:]]Group[[:space:]]Descriptor ]]; then
            in_section="descriptor"
            echo "$line" >> "$temp_file"
        # Handle nested list items based on current section
        elif [[ $in_section != "" && $line =~ ^[[:space:]]*[0-9]+\. ]]; then
            case $in_section in
                "account1")
                    if [[ $line =~ ^[[:space:]]*1\. ]]; then
                        echo "   1. ${app_name}${project_name}SNFR1" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*2\. ]]; then
                        echo "   2. ${app_name}${project_name}SNFP1" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*3\. ]]; then
                        echo "   3. ${app_name}${project_name}SNFQ1" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
                "account2")
                    if [[ $line =~ ^[[:space:]]*1\. ]]; then
                        echo "   1. ${app_name}${project_name}SNFR2" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*2\. ]]; then
                        echo "   2. ${app_name}${project_name}SNFP2" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*3\. ]]; then
                        echo "   3. ${app_name}${project_name}SNFQ2" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
                "alias")
                    if [[ $line =~ ^[[:space:]]*1\. ]]; then
                        echo "   1. domino-ENT-${project_name,,}-small-batch-SNFR" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*2\. ]]; then
                        echo "   2. domino-ENT-${project_name,,}-small-batch-SNFP" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*3\. ]]; then
                        echo "   3. domino-ENT-${project_name,,}-small-batch-SNFQ" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
                "descriptor")
                    # Remove dashes for group descriptors
                    local clean_project=$(echo "$project_name" | tr -d '-')
                    local clean_app=$(echo "$app_name" | tr -d '-')
                    if [[ $line =~ ^[[:space:]]*1\. ]]; then
                        echo "   1. ${clean_app}${clean_project}READ" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*2\. ]]; then
                        echo "   2. ${clean_app}${clean_project}P" >> "$temp_file"
                    elif [[ $line =~ ^[[:space:]]*3\. ]]; then
                        echo "   3. ${clean_app}${clean_project}Q" >> "$temp_file"
                        in_section=""
                    fi
                    ;;
            esac
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$md_file"  # Added file reference here
    
    # Replace original file with modified content
    mv "$temp_file" "$md_file"
}

# Main script modifications
# Keep the existing project_name and app_name validation...

# Create output directory (using existing rooster_outputs)
template_md="/path/to/your/template.md"  # Replace with actual path
output_md="rooster_outputs/$(basename "$template_md")"

# Copy the template MD file to rooster_outputs directory
cp "$template_md" "$output_md"

# Update the copied MD file
update_md_file "$output_md" "$app_name" "$project_name"

echo "Updated markdown file has been generated in $output_md"