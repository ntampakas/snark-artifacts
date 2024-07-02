#!/bin/bash
set -ex

artifacts=$(ls packages/ | grep -v 'artifacts\|cli')

cd packages

for artifact in $artifacts; do
  aws cloudfront get-function --name $artifact --stage LIVE output

  package_latest_version=$(jq -r '.version' "$artifact/package.json")
  package_current_version=$(egrep 'request.uri =' output | awk -F"/" '{ print $6 }')

  if [ $package_latest_version != $package_current_version ]; then
    echo "Modify function"
    sed -i "s/$current_version/$latest_version/" output
    etag=$(aws cloudfront describe-function --name $package --query 'ETag' --output text)
    aws cloudfront update-function --name $package --if-match $etag --function-config '{"Comment": "Update version", "Runtime": "cloudfront-js-2.0"}' --function-code fileb://output
    #etag=$(aws cloudfront describe-function --name $package --query 'ETag' --output text)
    #aws cloudfront publish-function --name $package --if-match $etag
  else
    echo "No changes"
  fi
done

exit 0
