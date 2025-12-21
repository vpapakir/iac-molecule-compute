#!/bin/bash

# Deploy CodePipeline for iac-molecule-compute
# Usage: ./deploy-pipeline.sh <github-owner> <github-token>

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <github-owner> <github-token>"
    echo "Example: $0 myusername ghp_xxxxxxxxxxxx"
    exit 1
fi

GITHUB_OWNER=$1
GITHUB_TOKEN=$2
STACK_NAME="iac-molecule-compute-pipeline"

echo "Deploying CodePipeline stack..."

aws cloudformation deploy \
    --template-file pipeline.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        GitHubOwner=$GITHUB_OWNER \
        GitHubToken=$GITHUB_TOKEN \
    --capabilities CAPABILITY_IAM \
    --region us-east-1

echo "Pipeline deployed successfully!"
echo "Stack name: $STACK_NAME"

# Get pipeline URL
PIPELINE_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query 'Stacks[0].Outputs[?OutputKey==`PipelineName`].OutputValue' \
    --output text \
    --region us-east-1)

echo "Pipeline URL: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$PIPELINE_NAME/view"