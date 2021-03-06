#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

level=$1
if [ -z "$level" ]; then
  level=1
fi
echo "starting: ${BASH_SOURCE[@]##*/} <LOG_LEVEL=$1>"

#echo "sourcing init"
source this
source test.suite

log.level $level

competionArray=(once config list file ite)
source oo

test.os() 
{
((TEST_COUNTER++))
console.log "


Test 0: os \"$*\"
===================================================================="
os.start "$@"
console.log "RETURN: $RETURN_VALUE  Result: $RESULT 
===================================================================="
}

test.case - "os test start" \
   os $*
expect 0 "*" "Test start"

source os

### test.method

