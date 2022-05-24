#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

#echo "starting: $0 <LOG_LEVEL=$1>"

fs.ln()     # <$lnMode> <$thePath> <?$targetDir> <?$called> <?$group> <$allUsers> # Creates a Symbolic Link 
{
  local lnMode=$1
  shift
  if [ -n "$lnMode" ]; then
    info.log "lnMode is set to $lnMode"
  else
    create.result 1 "No Symbolic link parameters given. Using: $linkPath"
    exit "$(result)"
  fi
  if [[ $lnMode == 'create' ]]; then
    symbolicLink create "$@"
  elif [[ $lnMode == 'delete' ]]; then
    symbolicLink delete "$@"
  else
    create.result 1 "$lnMode is not a correct symbolic link mode. Using: $linkPath"
    exit "$(result)"
  fi

 return $(result)
}

### new.method

fs.usage()
{
  local this=${0##*/}
  echo "You started" 
  echo "$0

  ln (symbolic link):
    1. create a symbolic link with the necessary parameters
    2. delete a symbolic link with the necessary parameters

  Usage:
  $this: command   Parameter and Description"
  this.help
  echo "
  
  Examples
    $this v
    $this init
    $this ln create /var/dev at ~/tmp called oosh in group dev for all users
    $this ln delete ~/oosh out of group dev for all users
    $this ln create /var/dev called oosh in group dev for users snet
    $this ln delete ~/oosh out of group dev for users snet
    ----------
  "
}

fs.start()
{
  #echo "sourcing init"
  source this

  # if [ -z "$1" ]; then
  #   status.discover "$@"
  #   return 0
  # fi

  this.start "$@"
}

fs.start "$@"

