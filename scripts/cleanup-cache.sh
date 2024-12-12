#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Repository owner and name
REPO_OWNER=${GITHUB_REPOSITORY_OWNER}  # From GitHub context
REPO_NAME=$(basename "${GITHUB_REPOSITORY}")  # From GitHub context

# GitHub token for authentication
GITHUB_TOKEN=${GITHUB_TOKEN}  # Must be provided as a secret in the workflow

# Base API URL
API_URL="https://api.github.com"

# Function to fetch all packages
list_packages() {
    curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "${API_URL}/orgs/${REPO_OWNER}/packages?package_type=container" | jq -r '.[].name'
}

# Function to delete a package
delete_package() {
    local package_name=$1
    echo "Deleting package: ${package_name}"
    curl -s -X DELETE -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "${API_URL}/orgs/${REPO_OWNER}/packages/container/${package_name}" \
        || echo "Failed to delete package: ${package_name}"
}

# Main script
echo "Listing all packages in the repository '${REPO_OWNER}/${REPO_NAME}'..."
packages=$(list_packages)

if [ -z "${packages}" ]; then
    echo "No packages found."
else
    for package in ${packages}; do
        #delete_package "${package}"
        echo "Will delete ${package}"
    done
    echo "All packages have been deleted."
fi
