#!/bin/bash

# Define variables
SONAR_HOST_URL="http://your-sonarqube-server"
SONAR_API_URL="$SONAR_HOST_URL/api"
PROJECT_KEY="your_project_key"
TOKEN="your_sonarqube_token"

# Check Prerequisites
echo "Checking prerequisites..."
if ! command -v curl &> /dev/null
then
    echo "Error: curl is not installed."
    exit 1
fi
echo "Prerequisites check completed."

# Function to fetch code coverage
fetch_code_coverage() {
    echo "Fetching code coverage..."
    local response=$(curl -s -u $TOKEN: "$SONAR_API_URL/measures/component?component=$PROJECT_KEY&metricKeys=coverage")
    local coverage=$(echo $response | jq -r '.component.measures[0].value')
    if [[ "$coverage" != "null" ]]; then
        echo "Code coverage: $coverage%"
    else
        echo "Failed to fetch code coverage."
        exit 1
    fi
}

# Function to fetch quality gate status
fetch_quality_gate_status() {
    echo "Fetching quality gate status..."
    local response=$(curl -s -u $TOKEN: "$SONAR_API_URL/qualitygates/project_status?projectKey=$PROJECT_KEY")
    local status=$(echo $response | jq -r '.projectStatus.status')
    if [[ "$status" != "null" ]]; then
        echo "Quality gate status: $status"
    else
        echo "Failed to fetch quality gate status."
        exit 1
    fi
}

# Error Handling
set -e

# Main execution
echo "Starting SonarQube analysis..."
fetch_code_coverage
fetch_quality_gate_status
echo "SonarQube analysis completed successfully."

