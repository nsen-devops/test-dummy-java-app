#!/bin/bash

# Setup and Configuration
NEXUS_IQ_URL="http://nexusiq.example.com"
APPLICATION_ID="yourApplicationId"
AUTH="admin:admin123" # Base64 encoded credentials
REPORT_DIR="./reports"
LOG_FILE="./nexus_scan.log"

# Create report and log directories if they don't exist
mkdir -p $REPORT_DIR
touch $LOG_FILE

# Script Input
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <artifact_path>"
    exit 1
fi

ARTIFACT_PATH=$1

# Logging function
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Error Handling
handle_error() {
    log "Error: $1"
    exit 1
}

# Scanning Process
log "Starting scan for artifact: $ARTIFACT_PATH"

# Encode credentials
ENCODED_AUTH=$(echo -n $AUTH | base64)

# Start a new scan
SCAN_RESPONSE=$(curl -s -u $AUTH -X POST "$NEXUS_IQ_URL/api/v2/scan/applications/$APPLICATION_ID/sources" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$ARTIFACT_PATH")
SCAN_ID=$(echo $SCAN_RESPONSE | jq -r '.id')

if [ "$SCAN_ID" == "null" ]; then
    handle_error "Failed to start scan for artifact: $ARTIFACT_PATH"
fi

log "Scan started successfully. Scan ID: $SCAN_ID"

# Poll for scan results
while true; do
    RESULT=$(curl -s -u $AUTH "$NEXUS_IQ_URL/api/v2/scan/applications/$APPLICATION_ID/reports/$SCAN_ID")
    STATUS=$(echo $RESULT | jq -r '.status')

    if [ "$STATUS" == "Complete" ]; then
        log "Scan completed."
        break
    elif [ "$STATUS" == "Failed" ]; then
        handle_error "Scan failed for artifact: $ARTIFACT_PATH"
    fi

    log "Scan status: $STATUS. Polling again in 10 seconds..."
    sleep 10
done

# Generate report
REPORT_FILE="$REPORT_DIR/report_$SCAN_ID.txt"
echo "Vulnerability Report for $ARTIFACT_PATH" > $REPORT_FILE
echo "---------------------------------------" >> $REPORT_FILE

jq -r '.components[] | select(.securityData.securityIssues[] | .severity == "Critical" or .severity == "High" or .severity == "Medium") | .hash + " " + .securityData.securityIssues[].severity + ": " + .securityData.securityIssues[].reference' <<< "$RESULT" >> $REPORT_FILE

log "Report generated at $REPORT_FILE"

# Recommendations
echo "Recommendations:" >> $REPORT_FILE
echo "1. Update to the latest versions of the dependencies." >> $REPORT_FILE
echo "2. Apply security patches available." >> $REPORT_FILE
echo "3. Review and follow best security practices for dependency management." >> $REPORT_FILE

log "Scan and report generation completed successfully."

