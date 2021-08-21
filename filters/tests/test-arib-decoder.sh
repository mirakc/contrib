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

export MIRAKC_B1_DECODER=true
export MIRAKC_B25_DECODER=true

test "$(echo 0 | $PROJDIR/arib-decoder GR 2>&1)" = 'Use B25 decoder'
check $? 'Should use B25 decoder'

test "$(echo 0 | $PROJDIR/arib-decoder BS 2>&1)" = 'Use B25 decoder'
check $? 'Should use B25 decoder'

test "$(echo 0 | $PROJDIR/arib-decoder CS 2>&1)" = 'Use B25 decoder'
check $? 'Should use B25 decoder'

test "$(echo 0 | $PROJDIR/arib-decoder SKY 2>&1)" = 'Use B1 decoder'
check $? 'Should use B1 decoder'
