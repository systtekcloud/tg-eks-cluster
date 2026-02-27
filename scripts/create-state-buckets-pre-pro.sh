#!/bin/bash
#------------------------------------------------------------------------------
# Create/Configure S3 State Buckets for all environments (DEV, PRE, PRO)
# - DEV bucket already exists: verify and fix configuration if needed
# - PRE and PRO buckets: create if they don't exist
#------------------------------------------------------------------------------

set -e

REGION="eu-west-1"
PROFILE="devops"
PROJECT_NAME="secure-platform"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to verify and fix bucket configuration
verify_and_fix_bucket() {
  local ENV=$1
  local ACCOUNT_ID=$2
  local BUCKET_NAME="${PROJECT_NAME}-tfstate-${ENV}"
  local NEEDS_FIX=false

  echo ""
  echo -e "${YELLOW}=========================================${NC}"
  echo -e "${YELLOW}Verifying bucket: ${BUCKET_NAME}${NC}"
  echo -e "${YELLOW}Account: ${ACCOUNT_ID}${NC}"
  echo -e "${YELLOW}=========================================${NC}"

  # Use tfadmin role in the target account
  local ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/tfadmin"

  echo "Assuming role: ${ROLE_ARN}..."
  local CREDS=$(aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "verify-bucket-${ENV}" \
    --profile "${PROFILE}" \
    --output json)

  export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

  # Check if bucket exists
  if ! aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "Bucket does not exist, will be created..."
    NEEDS_FIX=true
  fi

  # Check versioning
  echo -n "Checking versioning... "
  local VERSIONING=$(aws s3api get-bucket-versioning --bucket "${BUCKET_NAME}" 2>/dev/null | jq -r '.Status // "Not Set"')
  if [ "$VERSIONING" != "Enabled" ]; then
    echo -e "${YELLOW}NOT ENABLED (Current: $VERSIONING)${NC}"
    NEEDS_FIX=true
  else
    echo -e "${GREEN}✓${NC}"
  fi

  # Check encryption
  echo -n "Checking encryption... "
  if aws s3api get-bucket-encryption --bucket "${BUCKET_NAME}" &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${YELLOW}NOT ENABLED${NC}"
    NEEDS_FIX=true
  fi

  # Check public access block
  echo -n "Checking public access block... "
  local PUBLIC_BLOCK=$(aws s3api get-public-access-block --bucket "${BUCKET_NAME}" 2>/dev/null | jq -r '.PublicAccessBlockConfiguration | "\(.BlockPublicAcls)-\(.IgnorePublicAcls)-\(.BlockPublicPolicy)-\(.RestrictPublicBuckets)"')
  if [ "$PUBLIC_BLOCK" == "true-true-true-true" ]; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${YELLOW}NOT PROPERLY CONFIGURED${NC}"
    NEEDS_FIX=true
  fi

  # Apply fixes if needed
  if [ "$NEEDS_FIX" = true ]; then
    echo -e "${YELLOW}Applying fixes...${NC}"
    configure_bucket "$BUCKET_NAME" "$ACCOUNT_ID"
  else
    echo -e "${GREEN}✅ Bucket is properly configured!${NC}"
  fi

  # Unset temporary credentials
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

# Function to configure a bucket (create or update)
configure_bucket() {
  local BUCKET_NAME=$1
  local ACCOUNT_ID=$2

  # Check if bucket exists, create if not
  if ! aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "Creating S3 bucket..."
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi

  echo "Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  echo "Enabling encryption..."
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }]
    }'

  echo "Blocking public access..."
  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "Adding bucket policy..."
  aws s3api put-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --policy '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "AllowAccountFullAccess",
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::'"${ACCOUNT_ID}"':root"
          },
          "Action": "s3:*",
          "Resource": [
            "arn:aws:s3:::'"${BUCKET_NAME}"'",
            "arn:aws:s3:::'"${BUCKET_NAME}"'/*"
          ]
        }
      ]
    }'

  echo -e "${GREEN}✅ Bucket ${BUCKET_NAME} configured successfully!${NC}"
}

# Main execution
echo "Starting state bucket verification and configuration for all environments..."
echo ""

# DEV environment (account: 899237616120) - verify and fix if needed
verify_and_fix_bucket "dev" "899237616120"

# PRE environment (account: 942540403739) - verify and fix if needed
verify_and_fix_bucket "pre" "942540403739"

# PRO environment (account: 302442772527) - verify and fix if needed
verify_and_fix_bucket "pro" "302442772527"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✅ All state buckets are ready!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Bucket structure:"
echo "  - secure-platform-tfstate-dev (Account: 899237616120)"
echo "  - secure-platform-tfstate-pre (Account: 942540403739)"
echo "  - secure-platform-tfstate-pro (Account: 302442772527)"
echo ""
echo "You can now run: cd config/eu-west-1 && terragrunt run-all plan"
