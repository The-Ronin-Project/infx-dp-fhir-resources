#!/bin/bash

GREP=grep
TAIL=tail
SED=sed
HEAD=head
CURL=curl
NPM=npm
TR=tr
CAT=cat
CUT=cut
XARGS=xargs
JQ=jq
JAVA=java

shw_grey () {
    echo $(tput bold)$(tput setaf 0) $@ $(tput sgr 0)
}

shw_norm () {
    echo $(tput bold)$(tput setaf 6) $@ $(tput sgr 0)
}

shw_info () {
    echo $(tput bold)$(tput setaf 4) $@ $(tput sgr 0)
}

shw_warn () {
    echo $(tput bold)$(tput setaf 2) $@ $(tput sgr 0)
}

shw_err ()  {
    echo $(tput bold)$(tput setaf 1) $@ $(tput sgr 0)
}

check_exec () {
  if ! type $@ > /dev/null; then
	  shw_err "ERROR: Script needs $@ to create Zen profile. Please install $@."
	  exit 1
  else
    shw_info "Found $@."
  fi
}

if [[ "${OSTYPE}" == "linux-gnu"* ]]; then
  shw_norm "Linux OS supports GNU tools. Continue..."
elif [[ "${OSTYPE}" == "darwin"* ]]; then
  shw_norm "MAC OS requires GNU tools."
  if ! type "ggrep" > /dev/null; then
    shw_err "ERROR: GNU grep required.  brew install grep"
    exit 1
  elif ! type "gsed" > /dev/null; then
    shw_err "ERROR: GNU sed required.  brew install gnu-sed"
    exit 1
  elif ! type "ghead" > /dev/null; then
    shw_err "ERROR: GNU coreutils required.  brew install coreutils"
    exit 1
  elif ! type "gtail" > /dev/null; then
    shw_err "ERROR: GNU coreutils required.  brew install coreutils"
    exit 1
  else
    shw_norm "GNU tools found!"
  fi
  GREP=ggrep
  SED=gsed
  HEAD=ghead
  TAIL=gtail
else
  shw_err "ERROR: ${OSTYPE} not supported."
  exit 1
fi

check_exec ${NPM}
check_exec ${CURL}
check_exec ${JQ}
check_exec ${JAVA}

ZEN_LANG_REPO="https://github.com/zen-lang/fhir/releases/latest/"
ZEN_LANG_DOWNLOAD="https://github.com/zen-lang/fhir/releases/download/"
ZEN_VERSION=$(${CURL} -s ${ZEN_LANG_REPO} | ${SED} 's/.*tag\/\(.*\)\".*/\1/')
ZEN_FHIR_JAR="zen-fhir-${ZEN_VERSION}-standalone.jar"
ZEN_FHIR_JAR_WILDCARD="zen-fhir-*-standalone.jar"
ZEN_FHIR_DOWNLOAD=${ZEN_LANG_DOWNLOAD}${ZEN_VERSION}
DLURL_ZEN_FHIR_JAR=${ZEN_FHIR_DOWNLOAD}/${ZEN_FHIR_JAR}

INPUT_CACHE_PATH="${PWD}/input-cache/"

if [ ! -d "${INPUT_CACHE_PATH}" ] ; then
  shw_err "${INPUT_CACHE_PATH} does not exist.  Run _updatePublisher.sh script and sushi to generate profile."
  exit 1
fi

ZEN_FHIR="${INPUT_CACHE_PATH}${ZEN_FHIR_JAR}"
JAR_LOCATION="${ZEN_FHIR}"


if test -f "${ZEN_FHIR}" ; then
	shw_norm "Zen FHIR jar FOUND in input-cache"
else
	shw_norm "Zen FHIR jar NOT FOUND in input-cache - downloading"
  rm ${INPUT_CACHE_PATH}${ZEN_FHIR_JAR_WILDCARD}
	${CURL} -L ${DLURL_ZEN_FHIR_JAR} -o "${JAR_LOCATION}" --create-dirs
  if [ $? -ne 0 ] ; then
    shw_err "Offline (or github is down), unable to download.  Exiting"
    exit 1
  fi
fi

SUSHI_CONFIG="${PWD}/sushi-config.yaml"

if ! test -f "${SUSHI_CONFIG}"; then
  shw_err "ERROR: ${SUSHI_CONFIG} not found!  Make sure you are in dp-ronin-fhir-profile directory."
  exit 1
fi

FHIR_VERSION=$(${CAT} sushi-config.yaml | ${GREP} 'fhirVersion: ' | ${TR} -d 'fhirVersion: ')
shw_info "FHIR version=${FHIR_VERSION}"

PACKAGE_VERSION=$(${CAT} sushi-config.yaml | ${GREP} 'version: ' | ${TR} -d 'version: ')
shw_info "Package version=${PACKAGE_VERSION}"

PACKAGE_NAME=$(${CAT} sushi-config.yaml | ${GREP} 'name: ' | ${HEAD} -1 | ${CUT} -d : -f 2 | ${XARGS})
shw_info "Package name=${PACKAGE_NAME}"

PACKAGE_OUTPUT_DIR="${PACKAGE_NAME}_package"
[ -d ${PACKAGE_OUTPUT_DIR} ] && rm -rf ${PACKAGE_OUTPUT_DIR}

FHIR_RESOURCES_DIR="input/resources"

DEPENDENCIES=$(${CAT} sushi-config.yaml \
               | ${GREP} -oPz '(?s)dependencies:(.*?)\n\S' \
               | ${TAIL} -n +2 \
               | ${HEAD} -n -1 \
               | ${SED} 's/: /@/' \
               | ${TR} -d '\n')

FHIR_DEP="hl7.fhir.r4.core@${FHIR_VERSION}"

shw_info "Package Name: ${PACKAGE_NAME}"
shw_info "Package Version: ${PACKAGE_VERSION}"
shw_info "Package Output Directory: ${PACKAGE_OUTPUT_DIR}"
shw_info "Package Dependencies: ${FHIR_DEP} ${DEPENDENCIES}" \
&& echo "Creating ${PACKAGE_OUTPUT_DIR}/" \
&& mkdir -p ${PACKAGE_OUTPUT_DIR} \
&& echo "Creating ${PACKAGE_OUTPUT_DIR}/.index.json" \
&& for file in $(ls ${FHIR_RESOURCES_DIR}/*.json)
do
  if [[ "null" != $(${CAT} $file | ${JQ} .url) ]]; then
    ${CAT} $file \
    | ${JQ} 'with_entries(select([.key] | inside(["resourceType", "id", "url", "version", "type"])))' \
    | ${JQ} --arg filename $(echo $file | ${SED} 's/.*\///') '. += {"filename": $filename}'
  fi;
done | ${JQ} '{"index-version": 1, "files": [inputs]}' > ${PACKAGE_OUTPUT_DIR}/.index.json \
&& echo "Creating ${PACKAGE_OUTPUT_DIR}/package.json" \
&& ${JQ} -n --arg name ${PACKAGE_NAME} --arg ver ${PACKAGE_VERSION} '{"name": $name, "version": $ver}' > "${PACKAGE_OUTPUT_DIR}/package.json" \
&& echo "Copying package FHIR resources" \
&& cp ${FHIR_RESOURCES_DIR}/*.json ${PACKAGE_OUTPUT_DIR} \
&& echo "Installing package FHIR ${NPM} dependencies" \
&& cd ${PACKAGE_OUTPUT_DIR} \
&& ${NPM} --registry https://packages.simplifier.net install ${DEPENDENCIES} \
&& ${NPM} --registry https://packages.simplifier.net install ${FHIR_DEP} \
&& cd ..

shw_info "Dependencies: ${DEPENDENCIES}"
shw_info "FHIR Dependencies: ${FHIR_DEP}"

PROFILE_OUTPUT="${PWD}/zen_output"
[ -d ${PROFILE_OUTPUT} ] && rm -rf ${PROFILE_OUTPUT}
mkdir ${PROFILE_OUTPUT}
cd ${PROFILE_OUTPUT} \
&& ${NPM} init -y

for pkg in ${DEPENDENCIES}; do
  PKG_NAME=`echo $pkg | ${TR} '@' ' ' | ${CUT} -d ' ' -f 1 | ${TR} '.' '-'`
  shw_norm "Installing ${PKG_NAME}"
  ${NPM} --registry https://registry.npmjs.org install @zen-lang/${PKG_NAME}
done

for pkg in ${FHIR_DEP}; do
  PKG_NAME=`echo $pkg | ${TR} '@' ' ' | ${CUT} -d ' ' -f 1 | ${TR} '.' '-'` 
  shw_norm "Installing ${PKG_NAME}"
  ${NPM} --registry https://registry.npmjs.org install @zen-lang/${PKG_NAME}
done

shw_warn "Wait for it..."
java -jar ${ZEN_FHIR} ${PWD}/../${PACKAGE_OUTPUT_DIR} ${PROFILE_OUTPUT}/node_modules/@zen-lang/ ${PACKAGE_VERSION} ${PACKAGE_NAME}
cd ..

RONIN_ZEN_PROFILE_DIR="ronin-zen-profile"
[ -d ${RONIN_ZEN_PROFILE_DIR} ] && rm -rf ${RONIN_ZEN_PROFILE_DIR}
mkdir ${RONIN_ZEN_PROFILE_DIR}

shw_info "Creating Ronin Zen Profile in ${PWD}/${RONIN_ZEN_PROFILE_DIR}"

cp -R ${PROFILE_OUTPUT}/node_modules/@zen-lang/*/* ${RONIN_ZEN_PROFILE_DIR}

echo -e "{ns ronin-fhir-us-oncology\n\timport #{RoninOncologyFHIRProfile hl7-fhir-r4-core hl7-fhir-us-core hl7-fhir-us-mcode}}" > ${RONIN_ZEN_PROFILE_DIR}/ronin-fhir-us-oncology.edn

shw_info "Cleaning up..."
rm -rf ${PACKAGE_OUTPUT_DIR} ${PROFILE_OUTPUT}
shw_norm "Done."
