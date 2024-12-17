#!/bin/bash

# Function to validate and format name
validate_name() {
    local name=$1
    local name_type=$2
    
    # Convert to lowercase initially for processing
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    
    # Check for whitespace
    if [[ "$name" =~ [[:space:]] ]]; then
        echo "Your $name_type contains white spaces, they'll be replaced with dashes"
        suggested_name=$(echo "$name" | tr '[:space:]' '-')
        echo "Suggested $name_type is: $suggested_name"
        while true; do
            read -p "Would you like to continue with this name? (y/n): " choice
            case "$choice" in
                y|Y ) name=$suggested_name; break;;
                n|N ) return 1;;
                * ) echo "Please answer y or n.";;
            esac
        done
    fi
    
    # Convert to uppercase for final output
    name=$(echo "$name" | tr '[:lower:]' '[:upper:]')
    echo "$name"
    return 0
}

extract_db_references() {
    local sql_file=$1
    # Look for references that come after FROM, JOIN, UPDATE, or INSERT INTO, including all three parts
    grep -Ei '(FROM|JOIN|UPDATE|INSERT INTO)\s+[[:alnum:]_]+\.[[:alnum:]_]+\.[[:alnum:]_]+' "$sql_file" | 
    grep -Eo '[[:alnum:]_]+\.[[:alnum:]_]+\.[[:alnum:]_]+' |
    # Remove any reference that starts with a common alias pattern (single letter or two letters followed by dot)
    grep -Ev '^[a-zA-Z]{1,2}\.'
}

parse_sql_files() {
    local sql_dir=$1
    local output_file=$2
    
    # Initialize the output file
    echo "Database Structure" > "$output_file"
    echo "=================" >> "$output_file"
    echo >> "$output_file"
    
    # Find all SQL files recursively
    find "$sql_dir" -type f -name "*.sql" | while read -r sql_file; do
        filename=$(basename "$sql_file")
        filename_without_ext="${filename%.sql}"
        title=$(echo "$filename_without_ext" | sed -e 's/_/ /g' -e 's/\b\(.\)/\u\1/g')
        
        echo "$title SQL" >> "$output_file"
        echo "$(printf '%0.s-' $(seq 1 ${#title}) )----" >> "$output_file"
        echo >> "$output_file"
        
        # Create temporary file for this SQL file's references
        temp_file=$(mktemp)
        extract_db_references "$sql_file" > "$temp_file"
        
        # Process databases
        databases=($(cut -d'.' -f1 "$temp_file" | sort -u))
        for db in "${databases[@]}"; do
            echo "-$db" >> "$output_file"
            
            # Get schemas for this database
            schemas=($(grep "^$db\." "$temp_file" | cut -d'.' -f2 | sort -u))
            for schema in "${schemas[@]}"; do
                echo "    *$schema" >> "$output_file"
                
                # Get tables for this database and schema
                grep "^$db\.$schema\." "$temp_file" | cut -d'.' -f3 | sort -u | while read table; do
                    echo "        #$table" >> "$output_file"
                done
            done
            echo >> "$output_file"
        done
        
        echo >> "$output_file"
        rm -f "$temp_file"
    done
}

generate_extract_sql() {
    local sql_dir=$1
    local extract_file=$2
    
    # Initialize the extract SQL file
    echo "-- Extract SQL Queries" > "$extract_file"
    echo >> "$extract_file"
    echo "WITH" >> "$extract_file"
    
    # Create temporary file for all references
    temp_file=$(mktemp)
    
    # Collect all references
    find "$sql_dir" -type f -name "*.sql" | while read -r sql_file; do
        extract_db_references "$sql_file" >> "$temp_file"
    done
    
    # Get unique references while preserving order
    mapfile -t references < <(sort -u "$temp_file")
    
    # Generate CTEs
    counter=1
    for ref in "${references[@]}"; do
        if [ $counter -eq 1 ]; then
            echo "    A${counter} AS" >> "$extract_file"
        else
            echo "    ,A${counter} AS" >> "$extract_file"
        fi
        
        echo "    (" >> "$extract_file"
        echo "        SELECT *" >> "$extract_file"
        echo "        FROM" >> "$extract_file"
        echo "            $ref" >> "$extract_file"
        echo "        LIMIT 1" >> "$extract_file"
        echo "    )" >> "$extract_file"
        echo >> "$extract_file"
        
        ((counter++))
    done
    
    if [ ${#references[@]} -gt 0 ]; then
        echo "SELECT" >> "$extract_file"
        echo "    'Data Preview' as DATA_PREVIEW" >> "$extract_file"
        echo "FROM" >> "$extract_file"
        echo "    A1" >> "$extract_file"
    fi
    
    echo ";" >> "$extract_file"
    rm -f "$temp_file"
}

# Get and validate project name
while true; do
    read -p "Enter project name: " project_name
    validated_project=$(validate_name "$project_name" "project name")
    if [ $? -eq 0 ]; then
        project_name=$validated_project
        break
    fi
done

# Get and validate application name
while true; do
    read -p "Enter application name: " app_name
    validated_app=$(validate_name "$app_name" "application name")
    if [ $? -eq 0 ]; then
        app_name=$validated_app
        break
    fi
done

# Get SQL directory
read -p "Enter the directory containing SQL files: " sql_dir

# Validate SQL directory
if [ ! -d "$sql_dir" ]; then
    echo "Error: Directory $sql_dir does not exist"
    exit 1
fi

# Create output directory
output_dir="rooster_outputs"
mkdir -p "$output_dir"

# Create output files
accounts_file="$output_dir/service_account_request.txt"
structure_file="$output_dir/db_request.txt"
extract_file="$output_dir/extract.sql"

# Generate the service account specifications file
{
    echo "Service Account Specifications"
    echo "============================="
    echo
    echo "Proposed Accounts:"
    echo "-----------------"
    echo "SNOWFLAKE Read:"
    echo "${app_name}${project_name}SNFR1"
    echo "${app_name}${project_name}SNFR2"
    echo
    echo "SNOWFLAKE Prod:"
    echo "${app_name}${project_name}SNFP1"
    echo "${app_name}${project_name}SNFP2"
    echo
    echo "SNOWFLAKE Stage:"
    echo "${app_name}${project_name}SNFQ1"
    echo "${app_name}${project_name}SNFQ2"
    echo
    echo "Proposed Account Alias:"
    echo "----------------------"
    echo "SNOWFLAKE Read:"
    echo "domino-ENT-${project_name,,}-small-batch-SNFR"
    echo
    echo "SNOWFLAKE Prod:"
    echo "domino-ENT-${project_name,,}-small-batch-SNFP"
    echo
    echo "SNOWFLAKE Stage:"
    echo "domino-ENT-${project_name,,}-small-batch-SNFQ"
    echo
    echo "Group Descriptor:"
    echo "----------------"
    # Remove dashes and convert to proper case for group descriptors
    clean_project=$(echo "$project_name" | tr -d '-')
    clean_app=$(echo "$app_name" | tr -d '-')
    echo "SNOWFLAKE Read:"
    echo "${clean_app}${clean_project}READ"
    echo
    echo "SNOWFLAKE Prod:"
    echo "${clean_app}${clean_project}P"
    echo
    echo "SNOWFLAKE Stage:"
    echo "${clean_app}${clean_project}Q"
} > "$accounts_file"

# Generate the database structure file
parse_sql_files "$sql_dir" "$structure_file"
# Generate the extract SQL file
generate_extract_sql "$sql_dir" "$extract_file"

echo "Service account specifications have been generated in $accounts_file"
echo "Database structure has been generated in $structure_file"
echo "Extract SQL has been generated in $extract_file"