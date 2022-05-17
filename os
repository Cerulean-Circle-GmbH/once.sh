#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

#echo "starting: $0 <LOG_LEVEL=$1>"

### new.method

os.info() {
  echo "              
          shell level: $SHLVL

                script: $0
                args  : $*
                dir   : $(pwd)

              hostname: $HOSTNAME
                type  : $HOSTTYPE
                OS    : $OSTYPE
       package manager: $OOSH_PM
    "
}

os.check() { # <method> # is true if an OS was detected. LOG LEVEL 4 to see output. 
  info.log "detecting OS:  $OSTYPE" 
  local method="$1"
  if [ -n "$1" ]; then
    shift
  fi
  case "$OSTYPE" in
    darwin*)
      info.log "      Mac OS detected"
      method="$method.darwin"
      ;;
    linux*)
      info.log "      Linux detected"
      method="$method.linux"
      ;;
    *)
      important.log "  could not determine OS... please contribute to os.check"
    ;;
  esac
  
  if this.functionExists "$method"; then
    create.result 0 "$method" "$1"
  else
    create.result 1 "$method.unknown" "$1"
  fi
  return $(result)
}


os.usage()
{
  local this=${0##*/}
  echo "You started" 
  echo "$0

  Usage:
  $this: command   description and Parameter

      usage     prints this dialog while it will print the status when there are no parameters          
      v         print version information
      init      initializes ...nothing yet
      ----      --------------------------"
  this.help
  echo "
  ${NO_COLOR}
  Examples
    $this v
    $this init

    code:${GREEN}
    source os

    if os.check ossh.service.status; then
      echo Will call ossh.service.status.detectedOS
      $RESULT "$@"
    else
      important.log "$RESULT is not supported"
    fi  


  "
}

os.start()
{
  #echo "sourcing init"
  source this

  # if [ -z "$1" ]; then
  #   status.discover "$@"
  #   return 0
  # fi

  this.start "$@"
}

os.start "$@"

