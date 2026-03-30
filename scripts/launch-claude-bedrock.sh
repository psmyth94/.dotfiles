#!/bin/bash

# AWS Bedrock Claude Code Launcher
# This script configures AWS authentication and launches Claude Code with Bedrock
# Usage: launch-claude-bedrock.sh [environment] [claude args...]
#   environment: dev, qa, staging, prod, or default

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse environment argument
ENVIRONMENT="${1:-default}"
if [[ "$ENVIRONMENT" =~ ^(dev|qa|staging|prod|default)$ ]]; then
  shift # Remove environment from arguments
else
  ENVIRONMENT="default"
fi

echo -e "${YELLOW}Configuring AWS Bedrock for Claude Code (${ENVIRONMENT})...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &>/dev/null; then
  echo "Error: AWS CLI not found. Please install it first."
  exit 1
fi

# Set AWS profile based on environment
case "$ENVIRONMENT" in
dev)
  export AWS_PROFILE="dev"
  ;;
qa)
  export AWS_PROFILE="qa"
  ;;
staging)
  export AWS_PROFILE="staging"
  ;;
prod)
  export AWS_PROFILE="prod"
  ;;
default)
  # Use existing AWS_PROFILE or default
  ;;
esac

# Check if AWS SSO profile is configured
if [ -n "$AWS_PROFILE" ]; then
  echo -e "${GREEN}Using AWS profile: $AWS_PROFILE${NC}"
  echo "Logging into AWS SSO..."
  aws sso login --profile="$AWS_PROFILE" 2>/dev/null || {
    echo -e "${YELLOW}SSO login failed or not required. Continuing...${NC}"
  }
else
  echo -e "${YELLOW}No AWS_PROFILE set. Checking for default credentials...${NC}"
fi

# Verify AWS credentials are available
if ! aws sts get-caller-identity &>/dev/null; then
  echo "Error: No valid AWS credentials found."
  echo "Either set AWS_PROFILE or run 'aws configure'"
  exit 1
fi

# Verify authentication
echo "Verifying AWS authentication..."
if aws sts get-caller-identity >/dev/null 2>&1; then
  echo -e "${GREEN}✓ AWS authentication verified${NC}"
else
  echo "Error: AWS authentication failed"
  exit 1
fi

# Set Bedrock environment variables
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1

REGION="us"
SONNET=${REGION}.anthropic.claude-sonnet-4-5-20250929-v1:0
OPUS=${REGION}.anthropic.claude-opus-4-1-20251101-v1:0
HAIKU=${REGION}.anthropic.claude-haiku-4-5-20251001-v1:0
NOVA_PRO=amazon.nova-pro-v1:0
NOVA_LITE=amazon.nova-lite-v1:0

export ANTHROPIC_MODEL=$SONNET
# export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
# export MAX_THINKING_TOKENS=1024

echo -e "${GREEN}✓ AWS Bedrock configuration complete${NC}"
echo -e "${GREEN}✓ Environment: $ENVIRONMENT${NC}"
echo -e "${GREEN}✓ Profile: ${AWS_PROFILE:-default}${NC}"
echo -e "${GREEN}✓ Region: $AWS_REGION${NC}"
echo -e "${GREEN}✓ Model: $ANTHROPIC_MODEL${NC}"
echo ""

# Launch Claude Code with all arguments passed through
echo -e "${YELLOW}Launching Claude Code...${NC}"
exec "claude" "$@"
