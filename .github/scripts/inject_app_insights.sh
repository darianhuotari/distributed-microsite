#!/bin/bash

# This script retrieves the Application Insights connection string from Terraform output
# based on the environment and injects it into an HTML file.

# --- Input Arguments ---
# $1: Absolute path to the HTML file (e.g., "$GITHUB_WORKSPACE/static/index.html")
# $2: The placeholder string in the HTML file (e.g., "APP_INSIGHTS_CONNECTION_STRING_PLACEHOLDER")
# $3: The deployment environment (e.g., "development", "production")
# $4: Absolute path to the directory containing Terraform files (e.g., "$GITHUB_WORKSPACE/infra")
# $5: The name of the Terraform output containing the connection string (default: "app_insights_connection_string")

# Ensure the script exits immediately if a command exits with a non-zero status.
set -e

# Check if required arguments are provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <html_file_path_abs> <placeholder_string> <environment> <terraform_dir_abs> [tf_output_name]"
    echo "  <html_file_path_abs>: Absolute path to the HTML file to modify (e.g., \$GITHUB_WORKSPACE/static/index.html)."
    echo "  <placeholder_string>: The string to replace in the HTML file (e.g., 'APP_INSIGHTS_CONNECTION_STRING_PLACEHOLDER')."
    echo "  <environment>: The deployment environment ('development' or 'production')."
    echo "  <terraform_dir_abs>: Absolute path to your Terraform configuration directory (e.g., \$GITHUB_WORKSPACE/infra)."
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
BACKEND_CONFIG_FILE="${TERRAFORM_DIR}/backends/${ENVIRONMENT}.tfbackend"

# Check if the Terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Terraform directory not found: $TERRAFORM_DIR"
    exit 1
fi

# Check if the backend config file exists
if [ ! -f "$BACKEND_CONFIG_FILE" ]; then
    echo "Error: Terraform backend configuration file not found: $BACKEND_CONFIG_FILE"
    exit 1
fi

echo "--- Starting Terraform Output Retrieval and HTML Injection ---"
echo "Environment: $ENVIRONMENT"
echo "HTML File: $HTML_FILE"
echo "Placeholder: $PLACEHOLDER"
echo "Terraform Directory (passed as absolute path): $TERRAFORM_DIR"
echo "Terraform Output Name: $TF_OUTPUT_NAME"
echo "Terraform Backend Config: $BACKEND_CONFIG_FILE"

# --- Change to the Terraform directory ONCE for all terraform commands ---
cd "$TERRAFORM_DIR" || { echo "Error: Could not change to Terraform directory: $TERRAFORM_DIR"; exit 1; }

# --- Step 1: Initialize Terraform Backend ---
echo "Initializing Terraform backend..."
terraform init -backend-config="$BACKEND_CONFIG_FILE" -no-color &>/dev/null || true
echo "Terraform backend initialized successfully."

# --- Step 2: Get Terraform Output ---
echo "Attempting to retrieve Terraform output '${TF_OUTPUT_NAME}'..."

# Run terraform output and redirect stdout and stderr to separate files
# This ensures $? captures the exit code of the terraform output command directly
terraform output -raw "$TF_OUTPUT_NAME" > /tmp/tf_stdout_ai.log 2> /tmp/tf_stderr_ai.log
EXIT_CODE=$? # Capture the exit code of the 'terraform output' command
TERRAFORM_RAW_OUTPUT=$(cat /tmp/tf_stdout_ai.log) # Read stdout from file
TERRAFORM_STDERR=$(cat /tmp/tf_stderr_ai.log)     # Read stderr from file

rm -f /tmp/tf_stdout_ai.log /tmp/tf_stderr_ai.log # Clean up temp files

# Trim all whitespace from the raw output (stdout)
APP_INSIGHTS_CONN_STR=$(echo "$TERRAFORM_RAW_OUTPUT" | xargs)

# Check if the command was successful AND the trimmed output is non-empty
# AND the trimmed output does NOT contain common warning/error messages
# AND the stderr does NOT contain common error messages
if [ "$EXIT_CODE" -eq 0 ] && \
   [ -n "$APP_INSIGHTS_CONN_STR" ] && \
   [[ ! "$APP_INSIGHTS_CONN_STR" =~ ^(Warning:|Error:|No outputs found|Please define an output|terraform console) ]] && \
   [[ ! "$TERRAFORM_STDERR" =~ ^(Error:|Failed to reload) ]]; then
    echo "Terraform output '${TF_OUTPUT_NAME}' retrieved successfully for $ENVIRONMENT."
else
    echo "Error: Terraform output '${TF_OUTPUT_NAME}' not found, was empty, or contained warnings/errors for $ENVIRONMENT."
    echo "Debug Info: Exit Code: '$EXIT_CODE'" # Added quotes to ensure it prints even if empty/problematic
    echo "Debug Info: Raw Output: '$TERRAFORM_RAW_OUTPUT'"
    echo "Debug Info: Trimmed Output: '$APP_INSIGHTS_CONN_STR'"
    echo "Debug Info: Stderr: '$TERRAFORM_STDERR'"
    # Exit with a non-zero code to fail the step if the connection string isn't retrieved successfully
    exit 1
fi

# Mask the secret in logs (GitHub Actions specific command)
echo "::add-mask::$APP_INSIGHTS_CONN_STR"
echo "Connection string successfully masked in logs."

# --- Step 3: Inject Connection String into HTML ---
echo "Injecting connection string into '$HTML_FILE'..."

# Add this debug line right before sed
echo "Checking HTML file existence and permissions:"
ls -l "$HTML_FILE" || { echo "ERROR: ls failed for $HTML_FILE"; exit 1; }
echo "Current working directory: $(pwd)" # Also check cwd

sed -i "s|${PLACEHOLDER}|${APP_INSIGHTS_CONN_STR}|g" "$HTML_FILE"

if [ $? -eq 0 ]; then
    echo "Successfully injected connection string into $HTML_FILE."
    echo "--- HTML Injection Complete ---"
else
    echo "Error: Failed to inject connection string into $HTML_FILE."
    exit 1
fi