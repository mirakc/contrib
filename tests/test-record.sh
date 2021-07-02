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

DIR=$(mktemp -d)
trap "rm -rf $DIR" EXIT

test "$(echo 1 | $PROJDIR/record 1 1 $DIR/test)" = 1
check $? "Should output 1"

RECORD="$(ls -1 $DIR)"
test -n $RECORD
check $? "Should create a file"

test "$(cat $DIR/$RECORD)" = 1
check $? "Should record 1"

rm -f $DIR/$RECORD

test "$(echo 1 | $PROJDIR/record 1 2 $DIR/test)" = 1
check $? "Should output 1"

RECORD="$(ls -1 $DIR)"
test -z $RECORD
check $? "Should not create a file"

exit $FAILED
