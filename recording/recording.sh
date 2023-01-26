PROGNAME="$(basename $0)"

START_FMT='(.program.startAt / 1000 | strflocaltime("%Y-%m-%d %H:%M"))'
# If no duration is specified, show startAt.
END_FMT='((.program.startAt + (.program.duration // 0)) / 1000 | strflocaltime("%Y-%m-%d %H:%M"))'
DURATION_FMT='((.program.duration // 0) / 60000)'
TAGS_FMT='(.tags | join(" "))'
FILTER="[.program.id, .state, $START_FMT, $END_FMT, $DURATION_FMT, .program.name, $TAGS_FMT]"

BASEURL=http://localhost:40772
FOLDER=
FORMATTER="jq -r '. | $FILTER | @csv'"
LIST_FORMATTER="jq -r '.[] | $FILTER | @csv'"

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [options] add <program-id>
  $PROGNAME [options] start-recording <program-id>
  $PROGNAME [options] delete <program-id>
  $PROGNAME [options] list
  $PROGNAME [options] show <program-id>
  $PROGNAME [options] clear
  $PROGNAME [options] clear-all
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show the help.

  -r, --raw
    Output JSON returned from mirakc.

  -b, --base-url <BASE_URL> [default: '$BASEURL']
    A base URL of mirakc to use.

  --folder <FOLDER> [default: '$FOLDER']
    The name (or relative path) of a folder to store recording files.

COMMANDS:
  add
    Add a recording schedule with the "manual" tag.

  start-recording
    Start recording with the "manual" tag.

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
EOF
    exit 0
}

make_json() {
  PROGRAM_ID=$1
  PROGRAM=$(curl "$BASEURL/api/programs/$PROGRAM_ID" -sG)
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
  curl "$BASEURL/api/recording/schedules" -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "$(make_json $1)"
}

start_recording() {
  curl "$BASEURL/api/recording/recorders" -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "$(make_json $1)"
}

delete() {
  curl "$BASEURL/api/recording/schedules/$1" -s \
    -X DELETE \
    -H 'Content-Type: application/json'
}

list() {
  curl "$BASEURL/api/recording/schedules" -sG
}

show() {
  curl "$BASEURL/api/recording/schedules/$1" -sG
}

clear() {
  curl "$BASEURL/api/recording/schedules?tag=manual" -s -X DELETE
}

clear_all() {
  curl "$BASEURL/api/recording/schedules" -s -X DELETE
}

while [ $# -gt 0 ]
do
  case "$1" in
    '-h' | '--help')
      help
      ;;
    '-r' | '--raw')
      FORMATTER=cat
      LIST_FORMATTER=cat
      shift
      ;;
    '-b' | '--base-url')
      BASEURL="$2"
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
    'start-recording')
      start_recording $2 | sh -c "$FORMATTER"
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
    *)
      break
      ;;
  esac
done
