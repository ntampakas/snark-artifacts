#!/bin/bash
set -e

artifacts=$(ls packages/ | grep -v 'artifacts\|cli')

cd packages

#for artifact in $artifacts; do
for artifact in "poseidon"; do
  aws cloudfront get-function --name $artifact --stage LIVE output >/dev/null 2>&1

  #package_latest_version=$(jq -r '.version' "$artifact/package.json")
  package_latest_version="1.0.1-beta.1"
  cloudfront_current_version=$(egrep 'request.uri =' output | awk -F"/" '{ print $6 }')

  if [ $package_latest_version != $cloudfront_current_version ]; then
    echo "Modifying $artifact function"
    sed -i "s/$cloudfront_current_version/$package_latest_version/" output
    etag=$(aws cloudfront describe-function --name $artifact --query 'ETag' --output text)
    aws cloudfront update-function --name $artifact --if-match $etag --function-config '{"Comment": "$artifact", "Runtime": "cloudfront-js-2.0"}' --function-code fileb://output >/dev/null 2>&1
    echo "Updating $artifact function"
    #etag=$(aws cloudfront describe-function --name $artifact --query 'ETag' --output text)
    #aws cloudfront publish-function --name $artifact --if-match $etag >/dev/null 2>&1
    #echo "Publishing $artifact"
  else
    echo "No changes applied for $artifact"
  fi
done

exit 0
