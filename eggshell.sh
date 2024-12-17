#!/bin/bash

# Function to validate project name
validate_project_name() {
    local name=$1
    
    # Convert to lowercase
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    
    # Check for whitespace
    if [[ "$name" =~ [[:space:]] ]]; then
        echo "Your project name contains white spaces, they'll be replaced with dashes"
        suggested_name=$(echo "$name" | tr '[:space:]' '-')
        echo "Suggested project name is: $suggested_name"
        while true; do
            read -p "Would you like to continue with this name? (y/n): " choice
            case "$choice" in
                y|Y ) name=$suggested_name; break;;
                n|N ) return 1;;
                * ) echo "Please answer y or n.";;
            esac
        done
    fi
    
    echo "$name"
    return 0
}

# Get and validate project name
while true; do
    read -p "Enter project name: " project_name
    
    # Validate and convert project name
    project_name=$(validate_project_name "$project_name")
    validation_status=$?
    
    if [ $validation_status -ne 0 ]; then
        continue
    fi
    
    # Check if directory exists before proceeding
    if [ -d "$project_name" ]; then
        read -p "Directory '$project_name' already exists. Do you want to override it? (y/n): " choice
        case $choice in
            [Yy]* )
                read -p "Please type the project name again to confirm override: " confirmation
                if [ "$confirmation" = "$project_name" ]; then
                    rm -rf "$project_name"
                    break
                else
                    echo "Project name doesn't match. Starting over."
                    continue
                fi
                ;;
            [Nn]* )
                echo "Program execution stopped."
                exit 0
                ;;
            * )
                echo "Please answer y or n."
                ;;
        esac
    else
        break
    fi
done

# Get other required directories
read -p "Enter model pickle file directory: " model_dir
model_dir="../$model_dir"

read -p "Enter source database tables directory: " source_db_dir
source_db_dir="../$source_db_dir"

read -p "Enter destination database tables directory: " dest_db_dir
dest_db_dir="../$dest_db_dir"

read -p "Enter conjur-strings: " conjur_strings

# Create directory and initialize git
mkdir -p "$project_name"
cd "$project_name"
git init

# Create temporary Python script to extract features
cat > "extract_features.py" << 'PYTHON_SCRIPT'
#!/usr/bin/env python3

import pickle
import sys
from sklearn.pipeline import Pipeline

def extract_feature_names(model_path):
    """
    Extract feature names from a pickled model in exact order.
    Handles different model types and pipeline structures.
    """
    try:
        with open(model_path, 'rb') as f:
            model = pickle.load(f)
        
        # Try different ways to get feature names depending on model type
        feature_names = None
        
        if hasattr(model, 'feature_names_in_'):
            # Most sklearn models after v1.0
            feature_names = model.feature_names_in_
        elif hasattr(model, 'feature_names_'):
            # Some older sklearn models
            feature_names = model.feature_names_
        elif isinstance(model, Pipeline):
            # For sklearn pipelines, try to get features from first step
            first_step = model.steps[0][1]
            if hasattr(first_step, 'feature_names_in_'):
                feature_names = first_step.feature_names_in_
            elif hasattr(first_step, 'feature_names_'):
                feature_names = first_step.feature_names_
        
        if feature_names is None:
            raise AttributeError("Could not find feature names in model")
            
        return feature_names
        
    except Exception as e:
        print(f"Error reading model: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: extract_features.py <model_pickle_path>", file=sys.stderr)
        sys.exit(1)
        
    feature_names = extract_feature_names(sys.argv[1])
    for feature in feature_names:
        print(feature)
PYTHON_SCRIPT

chmod +x extract_features.py

# Extract features and create model_inputs.txt
echo "Extracting model input features..."
if python3 ./extract_features.py "$model_dir" > "model_inputs.txt"; then
    echo "Successfully extracted model features to model_inputs.txt"
else
    echo "Error extracting model features"
    exit 1
fi

read -p "Enter conjur-strings: " conjur_strings

# Create initial README
cat > "README.md" << EOF
# Project: $project_name

Do NOT commit anything to master; this layer serves as a starting point for other layers
The ONLY thing you can do in master is to merge its direct children
EOF

# Create project structure
mkdir -p config
mkdir -p dags
mkdir -p models
mkdir -p sql
mkdir -p utils
touch __init__.py

# Store configuration as JSON
cat > "config/config.json" << EOF
{
    "model_directory": "$model_dir",
    "source_db_directory": "$source_db_dir",
    "destination_db_directory": "$dest_db_dir",
    "conjur_strings": "$conjur_strings"
}
EOF

# Add README files to each directory
echo "Configuration files directory" > config/README.md
echo "Airflow DAGs directory" > dags/README.md
echo "Model files directory" > models/README.md
echo "SQL queries directory" > sql/README.md
echo "Utility functions directory" > utils/README.md

# Initial commit with full structure
git add .
git commit -m "Initial commit with project structure"

# Create layer 1 and its features
git checkout -b "layer_1"
mkdir -p "l1"
echo "This is layer 1" > "l1/README.md"
git add .
git commit -m "Initialize layer_1"

git checkout -b "feature-dummy-offload"
echo "Dummy offload feature" > "l1/dummy_offload.txt"
git add .
git commit -m "Add dummy offload feature"

git checkout "layer_1"
git checkout -b "feature-dummy-deploy"
echo "Dummy deploy feature" > "l1/dummy_deploy.txt"
git add .
git commit -m "Add dummy deploy feature"

# Create layer 2 and its features
git checkout master
git checkout -b "layer_2"
mkdir -p "l2"
echo "This is layer 2" > "l2/README.md"
git add .
git commit -m "Initialize layer_2"

git checkout -b "feature-dummy-score"
echo "Dummy score feature" > "l2/dummy_score.txt"
git add .
git commit -m "Add dummy score feature"

git checkout "layer_2"
git checkout -b "feature-audience-dummy"
echo "Audience dummy feature" > "l2/audience_dummy.txt"
git add .
git commit -m "Add audience dummy feature"

# Create layer 3 and its subbranches
git checkout master
git checkout -b "layer_3"
mkdir -p "l3"
echo "This is layer 3" > "l3/README.md"
git add .
git commit -m "Initialize layer_3"

git checkout -b "layer_3_1"
echo "Layer 3.1 feature" > "l3/feature_3_1.txt"
git add .
git commit -m "Add layer 3.1 feature"

git checkout "layer_3"
git checkout -b "layer_3_2"
echo "Layer 3.2 feature" > "l3/feature_3_2.txt"
git add .
git commit -m "Add layer 3.2 feature"

# Return to master
git checkout master

# Create helper scripts directory
mkdir -p .git/helpers

# Create merge validation script
cat > ".git/helpers/validate-merge" << 'EOF'
#!/bin/bash
current_layer=$1
target_layer=$2
operation=$3  # 'merge' or 'rebase'

# Function to check if target is a direct child of current
is_direct_child() {
    local current=$1
    local target=$2
    
    # Check if child layer name starts with parent layer name followed by an underscore
    if [[ "$target" == "${current}_"* ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if target is a direct ancestor of current
is_direct_ancestor() {
    local current=$1
    local target=$2
    
    # Check if current layer name starts with target layer name followed by an underscore
    if [[ "$current" == "${target}_"* ]]; then
        return 0
    else
        return 1
    fi
}

if [ "$operation" = "merge" ]; then
    # For merges, check if target layer is a direct child
    if ! is_direct_child "$current_layer" "$target_layer"; then
        echo "Error: Layer $target_layer is not a direct child of $current_layer. Merge is not allowed."
        exit 1
    fi
elif [ "$operation" = "rebase" ]; then
    # For rebases, check if target layer is a direct ancestor
    if ! is_direct_ancestor "$current_layer" "$target_layer"; then
        echo "Error: Layer $target_layer is not a direct ancestor of $current_layer. Rebase is not allowed."
        exit 1
    fi
fi
EOF

chmod +x .git/helpers/validate-merge

# Create prepare-commit-msg hook
cat > ".git/hooks/prepare-commit-msg" << 'EOF'
#!/bin/bash

# Check if this is a merge commit
if [ -f ".git/MERGE_HEAD" ]; then
    current_layer=$(git rev-parse --abbrev-ref HEAD)
    target_layer=$(git rev-parse --abbrev-ref MERGE_HEAD)
    
    # Run validation
    if ! .git/helpers/validate-merge "$current_layer" "$target_layer" "merge"; then
        # If validation fails, abort the merge
        git merge --abort
        exit 1
    fi
fi
EOF

chmod +x .git/hooks/prepare-commit-msg

# Create pre-rebase hook
cat > ".git/hooks/pre-rebase" << 'EOF'
#!/bin/bash
current_layer=$(git rev-parse --abbrev-ref HEAD)
target_layer=$1

.git/helpers/validate-merge "$current_layer" "$target_layer" "rebase"
EOF

chmod +x .git/hooks/pre-rebase

echo "Project $project_name has been initialized successfully!"