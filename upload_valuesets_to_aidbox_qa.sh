#!/bin/bash

# This script uploads the valuesets from localhost to Aidbox QA.
# First go to portal.azure.com, dsstageroninaidbox, aidbox / fhir_profile / exports / value_sets
# Download the latest locally.  Keep it gzipped.

compressed_file=$1
client_secret=$2
base_url="https://qa.project-ronin.aidbox.app"
url="${base_url}/fhir/ValueSet"

if [[ $compressed_file != *.gz ]]
then
    echo "$compressed_file"
    exit 1
fi

if [[ $# -lt 2 || $compressed_file != *.gz ]]
then
    echo "Usage: $0 <compressed valueset ndjson file> <dp-curl-valueset client secret>"
    exit 1
fi


payload="{\"grant_type\": \"client_credentials\",\"client_id\": \"dp-curl-valueset\",\"client_secret\": \"${client_secret}\"}"
resp=$(curl -X POST ${base_url}/auth/token -H "Content-Type: application/json" --data "${payload}")
token_type=$(echo ${resp} | jq -r '.token_type')
if [[ $token_type != "Bearer" ]]
then
    echo "Failed to authenticate"
    exit 1
fi

token=$(echo ${resp} | jq -r '.access_token')
auth=$(echo ${token_type} ${token})

gunzip < ${compressed_file} | while read ln
do
    resource_type=$(echo ${ln} | jq -r '.resourceType')
    echo ${resource_type}
    if [ "${resource_type}" != "ValueSet" ]
    then
        echo "Not ValueSet - skipping ${resource_type}"
    else
        id=$(echo ${ln} | jq -r '.id')
        echo "PUT ${url}/${id}"
        curl -v -X PUT -H"Authorization: ${auth}" -H 'content-type:application/json' -d"${ln}" "${url}/${id}"
    fi
done

curl -X DELETE "${base_url}/Session" -H"Authorization: ${auth}"