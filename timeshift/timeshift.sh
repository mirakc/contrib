set -eu

PROGNAME="$(basename $0)"

DEFAULT_BASE_URL=${MIRAKC_REC_BASE_URL:-http://localhost:40772}

JSON=
BASE_URL=$DEFAULT_BASE_URL

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [options] status
  $PROGNAME [options] list <recorder>
  $PROGNAME [options] show <recorder> <record-id>
  $PROGNAME [options] stream <recorder> <record-id>
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show the help.

  -j, --json
    Output JSON.

  -b, --base-url <BASE_URL> [default: '$DEFAULT_BASE_URL']
    A base URL of mirakc to use.

COMMANDS:
  status
    Show status of recorders.

  list <recorder>
    List records of <recorder>.

  show <recoder> <record-id>
    Show metadata of a record specified by <record-id>.

  stream <recoder> <record-id>
    Streaming a record specified by <record-id>.

EXAMPLES:
  List records of a particular recorder:

    mirakc-timeshift list nhk

  Save the program information of a particular record in JSON:

    mirakc-timeshift --json show nhk 1688115600 | jq '.program' >record.m2ts.json

  Save a record to a file:

    mirakc-timeshift stream nhk 1688115600 >record.m2ts

NOTE:
  It's recommended to create a shell script named mirakc-timeshift like below:

    #!/bin/sh
    export MIRAKC_REC_BASE_URL=http://your-mirakc:40772
    sh /path/to/mirakc/contrib/timeshift/timeshift.sh "\$@"
EOF
    exit 0
}

status() {
  curl "$BASE_URL/api/timeshift" -sG
}

list() {
  curl "$BASE_URL/api/timeshift/$1/records" -sG
}

show() {
  curl "$BASE_URL/api/timeshift/$1/records/$2" -sG
}

stream() {
  curl "$BASE_URL/api/timeshift/$1/records/$2/stream" -sG
}

render_status() {
  DURATION_FMT='(.duration / 60 / 60 / 1000 | floor)'
  FILTER="[.name, .service.name, $DURATION_FMT, .recording, .currentRecordId]"
  LABELS='NAME\tSERVICE\tHOURS\tRECORDING\tON-AIR'

  RES=$(cat)
  if [ "$JSON" = 1 ]
  then
    RES=$(echo "$RES" | jq -Mc '.')
  else
    RES=$(echo "$RES" | jq -r ".[] | $FILTER | @tsv")
    RES=$(echo "$RES" | sed -e "1i $LABELS")
    RES=$(echo "$RES" | column -s$'\t' -t)
  fi
  echo "$RES"
}

render() {
  START_FMT='((.startTime / 1000 ) | strflocaltime("%Y-%m-%d %H:%M"))'
  END_FMT='((.startTime + .duration) / 1000 | strflocaltime("%Y-%m-%d %H:%M"))'
  DURATION_FMT='(.duration / 60000 | floor)'
  SIZE_MB='(.size / 10000000 | floor)'
  FILTER="[.id, .program.id, $START_FMT, $END_FMT, $DURATION_FMT, $SIZE_MB, .program.name]"
  LABELS='ID\tPROGRAM ID\tSTART\tEND\tMINS\tMB\tTITLE'

  TYP=$1

  RES=$(cat)
  if [ "$JSON" = 1 ]
  then
    RES=$(echo "$RES" | jq -Mc '.')
  else
    if [ "$TYP" = 'list' ]
    then
      RES=$(echo "$RES" | jq -r ".[] | $FILTER | @tsv")
    else
      RES=$(echo "$RES" | jq -r ". | $FILTER | @tsv")
    fi
    RES=$(echo "$RES" | sed -e "1i $LABELS")
    RES=$(echo "$RES" | column -s$'\t' -t)
  fi
  echo "$RES"
}

while [ $# -gt 0 ]
do
  case "$1" in
    '-h' | '--help')
      help
      ;;
    '-j' | '--json')
      JSON=1
      shift
      ;;
    '-b' | '--base-url')
      BASE_URL="$2"
      shift 2
      ;;
    'status')
      status | render_status
      shift
      ;;
    'list')
      list $2 | render 'list'
      shift 2
      ;;
    'show')
      show $2 $3 | render ''
      shift 3
      ;;
    'stream')
      stream $2 $3
      shift 3
      ;;
    *)
      break
      ;;
  esac
done
