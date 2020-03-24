#!/bin/bash

COMMAND=$1
REGION=$2
STACK_ID=$3

if ! type -p aws &>/dev/null; then
  echo "The aws CLI is not installed."
  echo "More info: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html"
fi

if [[ -z "$REGION" ]]; then
  usage
fi

usage() {
  echo "usage is:"
  echo "./aws-run.sh create [region]"
  echo "./aws-run.sh delete [region] [stack id]"
  exit
}

tidy_up() {
  aws cloudformation delete-stack \
    --stack-name "$(echo "$STACK_ID" | awk -F '/' '{print $2}')" --region="$REGION"
}

create() {
  # Create stack
  STACK_ID=$(aws cloudformation create-stack \
    --capabilities CAPABILITY_IAM \
    --template-body file://prerequisites.yaml \
    --stack-name aws-service-broker-prerequisites \
    --output text --query "StackId" \
    --region "${REGION}")
  # Wait for stack to complete
  until
    ST=$(aws cloudformation describe-stacks \
      --region "${REGION}" \
      --stack-name "${STACK_ID}" \
      --query "Stacks[0].StackStatus" \
      --output text)
    echo "$ST"
    echo "$ST" | grep "CREATE_COMPLETE"
  do
    sleep 5
  done
  # Get the username from the stack outputs
  USERNAME=$(aws cloudformation describe-stacks \
    --region "${REGION}" \
    --stack-name "${STACK_ID}" \
    --query "Stacks[0].Outputs[0].OutputValue" \
    --output text)
  # Create IAM access key. Note down the output, we'll need it when setting up the broker
  aws iam create-access-key \
    --user-name "${USERNAME}" \
    --output json \
    --query 'AccessKey.{KEY_ID:AccessKeyId,SECRET_ACCESS_KEY:SecretAccessKey}'
  echo "Stack ID: $STACK_ID"
}

case "$COMMAND" in

"create")
  create
  ;;

"delete")
  if [[ -z "$STACK_ID" ]]; then
    echo "Please provide a valid stack id."
    echo "You can list the stacks with:"
    echo "aws cloudformation list-stacks --region <replace with region>"
    usage
  fi
  tidy_up
  echo "Deleted stack $STACK_ID"
  ;;

*)
  usage
  ;;

esac
