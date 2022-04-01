#!/bin/bash

# This script lists all resources ending in Example01 or Test and 
# creates an example.ndjson.gz or test.ndjson.gz ready 
# to deploy to HealthSamurai devbox

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
VALID_URL='^(http{1}|https{1})(:\/{2})[-A-Za-z0-9_.]*(:[0-9]*)?(\/)?$'
file_count=1

usage () {
  echo -n "Usage: $0 -d {example|test} -a {aidbox_url} -v"
  echo ""
  echo -n "use \"-v\" to include DetectedEdVisit test data."
  echo ""
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

with_edvisits=false

while getopts vd:a: flag
do
  case "${flag}" in
    v) with_edvisits=true;;
    d) data=${OPTARG};;
    a) aidbox_url=${OPTARG};;
    *) usage ${OPTARG};;
  esac
done

if ! [[ $aidbox_url =~ $VALID_URL ]]; then
    echo "$aidbox_url link is not valid"
    echo "Link should be of the form http(s)://<host>(:<port>)"
    usage
fi

if [ ${data} = "example" ]; then
  fname_end="Example01"
elif [ ${data} = "test" ]; then
  fname_end="Test"
else
  echo -n "Unknown data requested"
  usage
fi

if ! type jq > /dev/null; then
  echo -e "${RED}ERROR: jq is not installed.  Please install jq.${NC}"
  exit 1
fi

PROJ_VERSION=`grep "version: " ${PWD}/sushi-config.yaml | cut -d' ' -f2 2>/dev/null`
TEMP_DIR="${PWD}/temp/stage"
mkdir -p ${TEMP_DIR}
cp ${PWD}/input/examples/*${fname_end}.json ${TEMP_DIR}

if [ ${data} = "test" ]; then
  echo -e "${GREEN}Copying ValueSet resources.${NC}"
  cp $(ls ${PWD}/input/resources/ValueSet-*.json | egrep -v '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{8}') ${TEMP_DIR}
  # ValueSets inherit the project version - we need to replace it with v1.0 to match EdVisitRationale instances"
  sed -i '' "s/${PROJ_VERSION}/v1.0/" ${TEMP_DIR}/ValueSet-*.json

  doc_ref=`ls ${TEMP_DIR}/*DocumentReference*${fname_end}.json 2>/dev/null`
  if [ ! -z "${doc_ref}" ]
  then
    # Process DocumentReference content.attachment.data
    for i in ${doc_ref}
    do
      dec_name=`cat ${i} | jq -r '.content[0].attachment.data' | base64 -d`
      echo -e "${GREEN}Inserting ${dec_name} in ${i}.${NC}"
      enc_file=`cat ${PWD}/custom/notes/${dec_name} | base64`
      f=`jq '.content[0].attachment.data = $newVal' --arg newVal ${enc_file} <<< cat ${i}`
      echo ${f} > ${i}
    done
  fi
fi

# This is only for DetectedEdVisits.
if [ ${with_edvisits} == true ]
then
  echo -e "${GREEN}Copying ED Visit resources.${NC}"
  cp ${PWD}/custom/resources/*${fname_end}.json ${TEMP_DIR}
fi

# Generate bundle.json without INFX ValueSets because the file is really large.
echo -e "${YELLOW}Note: Due to size restrictions, bundles do not contain INFX ValueSets.${NC}"
node ${PWD}/generate_bundle.js ${TEMP_DIR} ${aidbox_url}

# Add INFX ValueSets to generate a file for bulk upload
if [ ${data} = "test" ]; then
  echo -e "${YELLOW}Note: Bulk file contains INFX ValueSets.${NC}"
  cp ${PWD}/input/resources/ValueSet-*.json ${TEMP_DIR}
fi
files=`ls ${TEMP_DIR}/*.json 2>/dev/null`

if [ -z "${files}" ]
then
  echo -e "${RED}No test data found in ${PWD}/fsh-generated/resources.${NC}"
  echo ''
  echo "Compile the resources using the command:"
  echo -e "${GREEN}sushi .${NC}"
  echo ''
  exit 1
fi

echo '[' > ${data}.json
for i in $files
do
  if [ $file_count -gt 1 ]
  then
    echo ',' >> ${data}.json
  fi
  ((file_count+=1))
  cat $i >> ${data}.json
done
echo ']' >> ${data}.json
cat ${data}.json | jq -c '.[]' > ${data}.ndjson
gzip -9 ${data}.ndjson
rm ${data}.json
echo -e "${GREEN}Created ${PWD}/${data}.ndjson.gz that can be uploaded to devbox${NC}"
rm -rf ${TEMP_DIR}
