#!/bin/bash
set -ex

artifacts=$(ls packages/ | grep -v 'artifacts\|cli')

cd packages

for artifact in $artifacts; do
  aws cloudfront get-function --name $artifact --stage LIVE output >/dev/null 2>&1

  #package_latest_version=$(jq -r '.version' "$artifact/package.json")
  package_latest_version="1.0.0-beta"
  cloudfront_current_version=$(egrep 'request.uri =' output | awk -F"/" '{ print $6 }')

  if [ $package_latest_version != $cloudfront_current_version ]; then
    echo "Modify function"
    sed -i "s/$cloudfront_current_version/$package_latest_version/" output
    etag=$(aws cloudfront describe-function --name $artifact --query 'ETag' --output text)
    aws cloudfront update-function --name $artifact --if-match $etag --function-config '{"Comment": "Update version", "Runtime": "cloudfront-js-2.0"}' --function-code fileb://output
    #etag=$(aws cloudfront describe-function --name $artifact --query 'ETag' --output text)
    #aws cloudfront publish-function --name $artifact --if-match $etag
  else
    echo "No changes"
  fi
done

exit 0
