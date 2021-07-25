BASEDIR=$(cd $(dirname $0); pwd)
PROJDIR=$(cd $BASEDIR/..; pwd)

FAILED=0

check() {
  if [ $1 -ne 0 ]
  then
    echo "FAILED: $2"
    FAILED=1
  fi
}

test -z "$(echo 1 | $PROJDIR/replay 1 1 /dev/null)"
check $? "Should read from /dev/null"

test "$(echo 1 | $PROJDIR/replay 1 2 /dev/null)" = 1
check $? "Should output 1"

exit $FAILED
