#!/bin/bash

# This script retrieves the static_web_app_api_key from Terraform output.
# It sets the STATIC_WEB_APP_API_KEY environment variable for subsequent GitHub Actions steps.

# Ensure the script exits immediately if a command exits with a non-zero status.
set -e

# Initialize Terraform backend
# Redirect stderr to /dev/null and allow failure as init might have already run
terraform init -backend-config="backends/prod.tfbackend" -no-color &>/dev/null || true

# Attempt to get the Terraform output.
# Capture stdout and stderr separately to isolate the actual output.
# Use a temporary file for stderr to avoid mixing with stdout.
TERRAFORM_RAW_OUTPUT=$(terraform output -raw static_web_app_api_key 2> /tmp/tf_stderr.log)
EXIT_CODE=$?
TERRAFORM_STDERR=$(cat /tmp/tf_stderr.log)
rm -f /tmp/tf_stderr.log # Clean up temp file

# Trim all whitespace from the raw output (stdout)
TRIMMED_OUTPUT=$(echo "$TERRAFORM_RAW_OUTPUT" | xargs)

# Check if the command was successful AND the trimmed output is non-empty
# AND the trimmed output does NOT contain common warning/error messages
# AND the stderr does NOT contain common error messages
if [ "$EXIT_CODE" -eq 0 ] && \
   [ -n "$TRIMMED_OUTPUT" ] && \
   [[ ! "$TRIMMED_OUTPUT" =~ ^(Warning:|Error:|No outputs found|Please define an output|terraform console) ]] && \
   [[ ! "$TERRAFORM_STDERR" =~ ^(Error:|Failed to reload) ]]; then # Check stderr for critical errors
    API_KEY_VALUE="$TRIMMED_OUTPUT"
    echo "Terraform output 'static_web_app_api_key' retrieved successfully."
else
    echo "Terraform output 'static_web_app_api_key' not found, was empty, or contained warnings/errors. Setting API_KEY_VALUE to empty string."
    echo "Debug Info: Exit Code: $EXIT_CODE"
    echo "Debug Info: Trimmed Output: '$TRIMMED_OUTPUT'"
    echo "Debug Info: Stderr: '$TERRAFORM_STDERR'"
    API_KEY_VALUE="" # Ensure it's empty if conditions aren't met
fi

# Mask the secret in logs
echo "::add-mask::$API_KEY_VALUE"

# Store as environment variable for subsequent steps in the workflow
echo "STATIC_WEB_APP_API_KEY=$API_KEY_VALUE" >> "$GITHUB_ENV"

echo "masked key: $API_KEY_VALUE"