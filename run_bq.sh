#!/bin/bash

# Run all parts of the pipeline with a provided end date.
# options:
#    -s <YYYY-MM-DD>: start date to run pipeline from.
#    -e <YYYY-MM-DD>: end date to run pipeline to.
#    -m staging|production|sandbox: environment to use
#    -t : to do a test run (doesn't start dataflow)

usage() {
  echo "Usage: KEY_FILE=<path> $0 -s <YYYY-MM-DD> -e <YYYY-MM-DD> -m staging|production|sandbox [-t]" $1 1>&2; exit 1;
}

ENDDATE=""
STARTDATE=""
TEST=0
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while getopts ":t:e:s:m:" opt; do
  case $opt in
    e)
      ENDDATE=${OPTARG}
      ;;
    s)
      STARTDATE=${OPTARG}
      ;;
    m)
      echo "${OPTARG} environment"
      if [[ "${OPTARG}" == production ]]; then
        source $DIR/environments/production.sh
      elif [[ "${OPTARG}" == staging ]]; then
        source $DIR/environments/staging.sh
      elif [[ "${OPTARG}" == sandbox ]]; then
        source $DIR/environments/sandbox.sh
      else
        echo "BAD ARGUMENT TO $0: ${OPTARG}"
        exit 1
      fi
      ;;
    t)
      echo "Setting Test to 1" >&2
      TEST=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

DATAFLOW_DIR="${DIR}/dataflow"
JAR_BASEDIR="${DIR}/dataflow/target"
JAR_FILE="${JAR_BASEDIR}/mlab-vis-pipeline.jar"

if [ ! -f $JAR_FILE ]; then
  echo "JAR File not found at: ${JAR_FILE}. Trying to download it."
  $DIR/getjar.sh -m ${API_MODE}
fi

echo "Project: ${PROJECT}"
echo "Start date: ${STARTDATE}"
echo "End date: ${ENDDATE}"

echo 'Authenticate service account'
gcloud auth activate-service-account --key-file=${KEY_FILE}

KEY_FILE=`echo "$(cd "$(dirname "$KEY_FILE")"; pwd)/$(basename "$KEY_FILE")"`

# echo "moving into dir: ${DATAFLOW_DIR}"
cd ${DATAFLOW_DIR}

echo "Starting server for metrics & bigquery pipeline (DAY and HOUR)"

if [ -z "${ENDDATE}" ] && [ -z "${STARTDATE}" ]; then
  # empty start and end dates, going to let auto detection happen
  echo "Empty start and end dates, going to let pipeline determine dates."
  GOOGLE_APPLICATION_CREDENTIALS=${KEY_FILE} java -jar ${JAR_FILE} \
  --runner=com.google.cloud.dataflow.sdk.runners.DataflowPipelineRunner \
  --project=${PROJECT} --stagingLocation="${STAGING_LOCATION}" \
  --skipNDTRead=0 --test=${TEST} --diskSizeGb=30
else
  echo "Running on dates ${STARTDATE} - ${ENDDATE}"
  GOOGLE_APPLICATION_CREDENTIALS=${KEY_FILE} java -jar ${JAR_FILE} \
  --runner=com.google.cloud.dataflow.sdk.runners.DataflowPipelineRunner \
  --project=${PROJECT} --stagingLocation="${STAGING_LOCATION}" \
  --skipNDTRead=0 --startDate=${STARTDATE} --endDate=${ENDDATE} --test=${TEST} \
  --diskSizeGb=30
fi