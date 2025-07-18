#!/bin/bash

# This script retrieves the Application Insights connection string from Terraform output
# based on the environment and injects it into an HTML file.

# --- Input Arguments ---
# $1: Absolute path to the HTML file (e.g., "$GITHUB_WORKSPACE/source/index.html")
# $2: The placeholder string in the HTML file (e.g., "APP_INSIGHTS_CONNECTION_STRING_PLACEHOLDER")
# $3: The deployment environment (e.g., "development", "production")
# $4: (Optional) Path to the directory containing Terraform files RELATIVE TO THE STEP'S WORKING DIRECTORY (default: ".")
#     This argument is usually "." because the GHA step sets the working-directory already.
# $5: (Optional) The name of the Terraform output containing the connection string (default: "app_insights_connection_string")

# Check if required arguments are provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <html_file_path_abs> <placeholder_string> <environment> [terraform_dir_relative] [tf_output_name]"
    echo "  <html_file_path_abs>: Absolute path to the HTML file to modify (e.g., \$GITHUB_WORKSPACE/source/index.html)."
    echo "  <placeholder_string>: The string to replace in the HTML file (e.g., 'APP_INSIGHTS_CONNECTION_STRING_PLACEHOLDER')."
    echo "  <environment>: The deployment environment ('development' or 'production')."
    echo "  [terraform_dir_relative]: Optional. Path to your Terraform configuration directory relative to the step's working directory (default: '.')."
    echo "  [tf_output_name]: Optional. Name of the Terraform output containing the connection string (default: 'app_insights_connection_string')."
    exit 1
fi

# Assign arguments to variables
HTML_FILE="$1"
PLACEHOLDER="$2"
ENVIRONMENT="$3"
TERRAFORM_DIR="$4"
TF_OUTPUT_NAME="${5:-app_insights_connection_string}"

# --- Validate Environment ---
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    echo "Error: Invalid environment specified. Must be 'development' or 'production'."
    exit 1
fi

# --- Terraform Configuration Paths ---
# BACKEND_CONFIG_FILE needs to be relative to TERRAFORM_DIR
BACKEND_CONFIG_FILE="${TERRAFORM_DIR}/backends/${ENVIRONMENT}.tfbackend"

# Check if the Terraform directory exists (expects an absolute path for TERRAFORM_DIR)
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Terraform directory not found: $TERRAFORM_DIR"
    exit 1
fi

# Check if the backend config file exists (e.g., infra/backends/development.tfbackend)
if [ ! -f "$BACKEND_CONFIG_FILE" ]; then
    echo "Error: Terraform backend configuration file not found: $BACKEND_CONFIG_FILE"
    exit 1
fi

echo "--- Starting Terraform Output Retrieval and HTML Injection ---"
echo "Environment: $ENVIRONMENT"
echo "HTML File: $HTML_FILE"
echo "Placeholder: $PLACEHOLDER"
echo "Terraform Directory (relative to step's working-dir): $TERRAFORM_DIR"
echo "Terraform Output Name: $TF_OUTPUT_NAME"
echo "Terraform Backend Config: $BACKEND_CONFIG_FILE"

# --- Step 1: Initialize Terraform Backend ---
echo "Initializing Terraform backend..."
(
  cd "$TERRAFORM_DIR" || { echo "Error: Could not change to Terraform directory: $TERRAFORM_DIR"; exit 1; }
  # TEMPORARY CHANGE FOR DEBUGGING: REMOVE `&>/dev/null || true`
  terraform init -backend-config="$BACKEND_CONFIG_FILE" -no-color -input=false
  # The exit code check below will still catch critical failures.
)

# Check if terraform init truly failed (beyond just warnings)
# This will now catch any non-zero exit from terraform init
if [ $? -ne 0 ]; then
    echo "Error: Terraform initialization failed. Please check your Terraform configuration and backend setup."
    exit 1
fi
echo "Terraform backend initialized successfully."

# --- Step 2: Get Terraform Output ---
echo "Attempting to retrieve Terraform output '${TF_OUTPUT_NAME}'..."
(
  cd "$TERRAFORM_DIR" || { echo "Error: Could not change to Terraform directory: $TERRAFORM_DIR"; exit 1; }
  TERRAFORM_RAW_OUTPUT=$(terraform output -raw "$TF_OUTPUT_NAME" 2> /tmp/tf_stderr_ai.log)
)
EXIT_CODE=$? # Capture exit code of the subshell
TERRAFORM_STDERR=$(cat /tmp/tf_stderr_ai.log)
rm -f /tmp/tf_stderr_ai.log

APP_INSIGHTS_CONN_STR=$(echo "$TERRAFORM_RAW_OUTPUT" | xargs)

if [ "$EXIT_CODE" -eq 0 ] && \
   [ -n "$APP_INSIGHTS_CONN_STR" ] && \
   [[ ! "$APP_INSIGHTS_CONN_STR" =~ ^(Warning:|Error:|No outputs found|Please define an output|terraform console) ]] && \
   [[ ! "$TERRAFORM_STDERR" =~ ^(Error:|Failed to reload) ]]; then
    echo "Terraform output '${TF_OUTPUT_NAME}' retrieved successfully for $ENVIRONMENT."
else
    echo "Error: Terraform output '${TF_OUTPUT_NAME}' not found, was empty, or contained warnings/errors for $ENVIRONMENT."
    echo "Debug Info: Exit Code: $EXIT_CODE"
    echo "Debug Info: Raw Output: '$TERRAFORM_RAW_OUTPUT'"
    echo "Debug Info: Trimmed Output: '$APP_INSIGHTS_CONN_STR'"
    echo "Debug Info: Stderr: '$TERRAFORM_STDERR'"
    exit 1
fi

echo "::add-mask::$APP_INSIGHTS_CONN_STR"
echo "Connection string successfully masked in logs."

# --- Step 3: Inject Connection String into HTML ---
echo "Injecting connection string into '$HTML_FILE'..."
sed -i "s|${PLACEHOLDER}|${APP_INSIGHTS_CONN_STR}|g" "$HTML_FILE"

if [ $? -eq 0 ]; then
    echo "Successfully injected connection string into $HTML_FILE."
    echo "--- HTML Injection Complete ---"
else
    echo "Error: Failed to inject connection string into $HTML_FILE."
    exit 1
fi