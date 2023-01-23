PROGNAME="$(basename $0)"

BASEURL=http://localhost:40772
FOLDER=

help() {
    cat <<EOF >&2
USAGE:
  $PROGNAME [options] add <program-id>
  $PROGNAME [options] start-recording <program-id>
  $PROGNAME [options] delete <program-id>
  $PROGNAME [options] list
  $PROGNAME [options] clear
  $PROGNAME [options] clear-all
  $PROGNAME -h | --help

OPTIONS:
  -h, --help
    Show the help.

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

  clear
    Clear recording schedules added using this script.

  clear-all
    Clear all recording schedules.
EOF
    exit 0
}

make_json() {
  PROGRAM_ID=$1
  PROGRAM=$(curl $BASEURL/api/programs/$PROGRAM_ID -sG)
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
  curl $BASEURL/api/recording/schedules -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "$(make_json $1)"
}

start_recording() {
  curl $BASEURL/api/recording/recorders -s \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "$(make_json $1)"
}

delete() {
  curl $BASEURL/api/recording/schedules/$1 -s \
    -X DELETE \
    -H 'Content-Type: application/json'
}

list() {
  curl $BASEURL/api/recording/schedules -sG
}

clear() {
  curl "$BASEURL/api/recording/schedules?tag=manual" -s -X DELETE
}

clear_all() {
  curl $BASEURL/api/recording/schedules -s -X DELETE
}

while [ $# -gt 0 ]
do
  case "$1" in
    '-h' | '--help')
      help
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
      add $2
      shift 2
      ;;
    'start-recording')
      start_recording $2
      shift 2
      ;;
    'delete')
      delete $2
      shift 2
      ;;
    'list')
      list
      shift
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
