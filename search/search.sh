set -eu

PROGNAME="$(basename $0)"
BASE_DIR="$(cd $(dirname $0); pwd)"

PROGRAM_JQ_DIR=$BASE_DIR/../program-jq
CUSTOM_PROGRAM_JQ_DIR=${MIRAKC_SEARCH_CUSTOM_PROGRAM_JQ_DIR:-}
DEFAULT_BASE_URL=${MIRAKC_SEARCH_BASE_URL:-http://localhost:40772}

JSON=
BASE_URL=$DEFAULT_BASE_URL

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [options] [<filter>...]
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show the help.

  -j, --json
    Output JSON.

  -b, --base-url <BASE_URL> [default: '$DEFAULT_BASE_URL']
    A base URL of mirakc to use.

EXAMPLES:
  Show movies:
    $PROGNAME movie gt-1h

  Show BSP:
    $PROGNAME '[.[] | select(.serviceId == 103)]'

NOTE:
  It's recommended to create a shell script named mirakc-search like below:

    #!/bin/sh
    export MIRAKC_SEARCH_BASE_URL=http://your-mirakc:40772
    export MIRAKC_SEARCH_CUSTOM_PROGRAM_JQ_DIR=/path/to/program-jq
    sh /path/to/mirakc/contrib/search/search.sh "\$@"
EOF
    exit 0
}

log() {
  echo "$1" >&2
}

error() {
  log "ERROR: $1"
  exit 1
}

append_services() {
  SERVICES=$(curl "$BASE_URL/api/services" -sG | \
               jq -c 'map({ key: (.id | tostring), value: .name }) | from_entries')
  jq -f $PROGRAM_JQ_DIR/msid.jq | \
    jq --argjson SERVICES "$SERVICES" \
      'map(. + {service: $SERVICES[.msid | tostring]})'
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
    *)
      break
      ;;
  esac
done

RES=$(curl $BASE_URL/api/programs -sG)
RES=$(echo "$RES" | jq -f $PROGRAM_JQ_DIR/not-ended.jq)
for FILTER in "$@"
do
  if [ -f "$CUSTOM_PROGRAM_JQ_DIR/$FILTER.jq" ]
  then
    RES=$(echo "$RES" | jq -f $CUSTOM_PROGRAM_JQ_DIR/$FILTER.jq)
  else
    if [ -f "$PROGRAM_JQ_DIR/$FILTER.jq" ]
    then
      RES=$(echo "$RES" | jq -f $PROGRAM_JQ_DIR/$FILTER.jq)
    else
      RES=$(echo "$RES" | jq "$FILTER")
    fi
  fi
done
if [ "$JSON" = 1 ]
then
  RES=$(echo "$RES" | jq -Mc '.')
else
  RES=$(echo "$RES" | append_services)
  RES=$(echo "$RES" | jq -f $PROGRAM_JQ_DIR/localtime.jq)
  RES=$(echo "$RES" | jq -f $PROGRAM_JQ_DIR/summary.jq)
  RES=$(echo "$RES" | jq -r '. | @tsv')
  RES=$(echo "$RES" | sed -e '1i ID\tSTART\tEND\tMINS\tTITLE\tSERVICE')
  RES=$(echo "$RES" | column -s $'\t' -t)
fi

echo "$RES"
