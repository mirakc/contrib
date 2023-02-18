set -eu

PROGNAME="$(basename $0)"

START_FMT='(.program.startAt / 1000 | strflocaltime("%Y-%m-%d %H:%M"))'
# If no duration is specified, show startAt.
END_FMT='((.program.startAt + (.program.duration // 0)) / 1000 | strflocaltime("%Y-%m-%d %H:%M"))'
DURATION_FMT='((.program.duration // 0) / 60000)'
TAGS_FMT='(.tags | join(" "))'
FILTER="[.program.id, .state, $START_FMT, $END_FMT, $DURATION_FMT, .program.name, $TAGS_FMT]"

DEFAULT_BASE_URL=${MIRAKC_REC_BASE_URL:-http://localhost:40772}
DEFAULT_FOLDER=${MIRAKC_REC_FOLDER:-}

BASE_URL=$DEFAULT_BASE_URL
FOLDER=$DEFAULT_FOLDER

LABELS="sed -e '1i ID\tSTATE\tSTART\tEND\tMINS\tTITLE\tTAGS'"
COLUMN="column -s$'\t' -t"

FORMATTER="jq -r '. | $FILTER | @tsv'"
FORMATTER="$FORMATTER | $LABELS"
FORMATTER="$FORMATTER | $COLUMN"

LIST_FORMATTER="jq -r '.[] | $FILTER | @tsv'"
LIST_FORMATTER="$LIST_FORMATTER | $LABELS"
LIST_FORMATTER="$LIST_FORMATTER | $COLUMN"

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [options] add <program-id>
  $PROGNAME [options] delete <program-id>
  $PROGNAME [options] list
  $PROGNAME [options] show <program-id>
  $PROGNAME [options] clear
  $PROGNAME [options] clear-all
  $PROGNAME [options] start <program-id>
  $PROGNAME [options] stop <program-id>
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show the help.

  -j, --json
    Output JSON.

  -b, --base-url <BASE_URL> [default: '$DEFAULT_BASE_URL']
    A base URL of mirakc to use.

  --folder <FOLDER> [default: '$DEFAULT_FOLDER']
    The name (or relative path) of a folder to store recording files.

COMMANDS:
  add
    Add a recording schedule with the "manual" tag.

  delete
    Delete a recording schedule.

  list
    List recording schedules.

  show
    Show a recording schedule.

  clear
    Clear recording schedules added using this script.

  clear-all
    Clear all recording schedules.

  start
    Start recording with the "manual" tag.

  stop
    Stop a recording without deleting its recording schedule.

NOTE:
  It's recommended to create a shell script named mirakc-rec like below:

    #!/bin/sh
    export MIRAKC_REC_BASE_URL=http://your-mirakc:40772
    sh /path/to/mirakc/contrib/search/search.sh \$@
EOF
    exit 0
}

make_json() {
  PROGRAM_ID=$1
  PROGRAM=$(curl "$BASE_URL/api/programs/$PROGRAM_ID" -sG)
  DATE=$(echo "$PROGRAM" | jq -Mr '.startAt / 1000 | strflocaltime("%Y%m%d%H%M")')
  if [ -n "$FOLDER" ]
  then
    CONTENT_PATH="$FOLDER/${DATE}_${PROGRAM_ID}.m2ts"
  else
    CONTENT_PATH="${DATE}_${PROGRAM_ID}.m2ts"
  fi
  cat <<EOF | jq -Mc '.'
{
  "programId": $PROGRAM_ID,
  "options": {
    "contentPath": "$CONTENT_PATH"
  },
  "tags": ["manual"]
}
EOF
}

add() {
  curl "$BASE_URL/api/recording/schedules" -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "$(make_json $1)"
}

delete() {
  curl "$BASE_URL/api/recording/schedules/$1" -s \
    -X DELETE \
    -H 'Content-Type: application/json'
}

list() {
  curl "$BASE_URL/api/recording/schedules" -sG
}

show() {
  curl "$BASE_URL/api/recording/schedules/$1" -sG
}

clear() {
  curl "$BASE_URL/api/recording/schedules?tag=manual" -s -X DELETE
}

clear_all() {
  curl "$BASE_URL/api/recording/schedules" -s -X DELETE
}

start() {
  curl "$BASE_URL/api/recording/recorders" -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "$(make_json $1)"
}

stop() {
  curl "$BASE_URL/api/recording/recorders/$1" -s \
    -X DELETE \
    -H 'Content-Type: application/json'
}

while [ $# -gt 0 ]
do
  case "$1" in
    '-h' | '--help')
      help
      ;;
    '-j' | '--json')
      FORMATTER=cat
      LIST_FORMATTER=cat
      shift
      ;;
    '-b' | '--base-url')
      BASE_URL="$2"
      shift 2
      ;;
    '--folder')
      FOLDER="$2"
      shift 2
      ;;
    'add')
      add $2 | sh -c "$FORMATTER"
      shift 2
      ;;
    'delete')
      delete $2
      shift 2
      ;;
    'list')
      list | sh -c "$LIST_FORMATTER"
      shift
      ;;
    'show')
      show $2 | sh -c "$FORMATTER"
      shift 2
      ;;
    'clear')
      clear
      shift
      ;;
    'clear-all')
      clear_all
      shift
      ;;
    'start')
      start $2
      shift 2
      ;;
    'stop')
      stop $2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done
