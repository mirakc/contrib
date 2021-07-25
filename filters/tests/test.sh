set -eu

BASEDIR=$(cd $(dirname $0); pwd)

ls -1 $BASEDIR/test-* | while read TEST
do
  echo "$TEST..."
  sh $TEST
done
