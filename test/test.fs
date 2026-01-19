#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

level=$1
if [ -z "$level" ]; then
  level=1
fi
echo "starting: ${BASH_SOURCE[@]##*/} <LOG_LEVEL=$1>"

source this
source test.suite

log.level $level

# Check if fs script exists
if ! [ -f "$OOSH_DIR/fs" ] && ! [ -f "$OOSH_DIR/old/fs" ]; then
  echo -e "\e[1;33m  ⚠ SKIPPED: fs script not available (deprecated)\e[0m"
  test.suite.save.results
  exit 0
fi

# Source from old/ if that's where it is
if [ -f "$OOSH_DIR/old/fs" ]; then
  source "$OOSH_DIR/old/fs"
else
  source fs
fi

test.fs()
{
((TEST_COUNTER++))
console.log "


Test 0: fs \"$*\"
===================================================================="
fs.start "$@"
console.log "RETURN: $RETURN_VALUE  Result: $RESULT
===================================================================="
}

test.case - "fs test start" \
   fs $*
expect 0 "*" "Test start"


console.log "
Test 1 
===================================================================="

test.case - "Test if a ln is created"    fs.lnCreate /var/dev ~/ snetDev snetDev snet admin
expect 0 ""

### test.method

