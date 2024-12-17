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