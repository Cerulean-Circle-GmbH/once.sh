#!/bin/bash

# ONCE 4.3.0 test/sprint23

#export PS4='+${LINENO}: '
#source 'lib.trap.sh'
#DEBUG=ON
set -E
set -T


This=$(which $0)
this=$(basename $This)

once.version()              # prints out the hard coded version tag of $This | to update the script use e.g. once update here http://192.168.178.49:8080
{
 console.log "$0 version: 20210813 13:14"
}

if ! [ -x "$(command -v warn.log)" ]; then
    echo "no warn.log.... mitigated using internal functions...status: ok"
    silentDebug.log() {
        if [ "ON" = "$DEBUG" ]; then
            #test -t 1 && tput setf 7     
            #echo -e "\033[1;36m- $@\033[0m"
            echo -e "\e[0m\e[90m- $@\e[0m"
            #echo "- $@"
            #test -t 1 && tput sgr0 # Reset terminal
        fi
    }

    debug.log() {
      ( { set +x; } 2>/dev/null ; silentDebug.log $@)
    }

    console.log() {
        #test -t 1 && tput bold; tput setf 7                                            ## white bold
        echo -e "\033[0m>  $@"
        #test -t 1 && tput sgr0 # Reset terminal
    }
    error.log() {
        err.log "$@"
    }
    err.log() {
        #test -t 1 && tput bold; tput setf 4  
        #echo "ERROR>  $@"
        echo -e "\033[1;31mERROR> $@\033[0m"    
        #test -t 1 && tput sgr0 # Reset terminal
        #if [ "ON" = "$DEBUG" ]; then 
            export STEP_DEBUG=ON
        #fi   
    }
    warn.log() {
        #test -t 1 && tput bold; tput setf 6
        echo -e "\033[1;33m> WARNING $@\033[0m"                                    ## white yellow
        #test -t 1 && tput sgr0 # Reset terminal
    }
    stop.log() {
        if [ "ON" = "$DEBUG" ]; then 
            #test -t 1 && tput bold; tput setf 6                                    ## white yellow
            #echo "BREAKPOINT> $@"
            echo -e "\033[1;32mBREAKPOINT: line ${BASH_LINENO[0]}> $@\033[0m" 
            #test -t 1 && tput sgr0 # Reset terminal
            export STEP_DEBUG=ON
        fi  
    }
fi

if [ -x "$(command -v debug)" ]; then
  echo "sourcing $(which debug)"
  source debug
  export STEP_DEBUG=OFF
  warn.log "DEBUG is $DEBUG"  
else
  debug.version()              # prints out the hard coded version tag of $This 
  {
    echo "$0 debug version: 20210626 20:45"
  }

  function silentStep() {
    ( { set +x; } 2>/dev/null ; step )
  }


  function step()
  {

    if [ "$STEP_DEBUG" = "ON" ]; then
      echo -e "\033[37m+<-----------------------------------------"
      echo "> function ${FUNCNAME[1]}(" "${BASH_ARGV[@]}" ")  in file: ${BASH_SOURCE[1]}"
      echo -e "> line: ${BASH_LINENO[1]} '${BASH_COMMAND}'\033[0m"

      read -p '' CONT

      if [[ ! "$CONT" = "" ]]; then
        case $CONT in
          h)
              echo "
              h     this help
              e     expands variable in the command
              n     next command full with debug
              ENTER next command

              d     toggle debug messages
              t     trace the stack
              s     continue silently
              c     with debug
              p     print PATH
              ll    list dir
              cd    changing to entered path
              root  tree /root
              home  tree /home
              i     check eamd
              eamd  tree workspace

              cmd   runn command (BE CAREFULL)

              q     exit
                  all other commands exit too
              "
              step
              ;;
          s)
              removeTrap
              DEBUG=OFF
              debug.log "DEBUG is OFF"
              set +x
              ;;
          n)
              #removeTrap
              DEBUG=ON
              set -x
              ;;
          x)
              DEBUG=ON
              removeTrap
              set -x
              ;;
          c)
              DEBUG=ON
              removeTrap
              set +x
              ;;
          e)
              echo "> expands to: $(eval echo "$BASH_COMMAND")"
              step
              ;;
          r)
              export STEP_TILL_NEXT_RETURN=ON
              removeTrap
              warn.log "continue till next Return"
              step
              ;;
          t)
              stackTrace
              ;;
          ls)
              ls -al
              step 
              ;;
          d)
              toggleDebug
              step
              ;;
          p)
              console.log "PATH=$PATH"
              step
              ;;
          ll)
              pwd
              ls -alF
              step
              ;;
          root)
              tree -aL 2 /root
              step
              ;;
          home)
              tree -aL 2 /home
              step
              ;;
          eamd)
              tree -aL 2 /$defaultWorkspace/..
              step
              ;;
          i)
              eamd check
              step
              ;;
          cd)
              read -p 'cd to?   >' CD_DIR
              cd $CD_DIR
              step
              ;;
          cmd)
              read -p 'command?  BE CAREFULL >' command
              set -x
              $command
              step
              ;;    
          env)
              read -p 'ENV VARIBALE NAME>' env
              set -x
              echo -e "\033[1;33mexport $env=${!env}\033[0m"
              step
              ;;          
          *)
              set +x
              warn.log "FORCE EXIT because of command: $CONT"
              exit 0
        esac
      #else
        #echo "ENTER: continue"
      fi
    #else
      #echo "Step Debug is $STEP_DEBUG"
    fi
  }

  function stackTrace() {
              i=0;
              #for (( i=0; i<=${#BASH_LINENO[@]}; i++)); do
              echo -e "\033[1;37m" 
              for l in ${BASH_LINENO[@]}; do
                  printf "i: %2d  line: %6d  function: %-20s  file: %-30s   args: " "$i" "$l" "${FUNCNAME[$i]}()" "${BASH_SOURCE[$i]}"
                  echo ${BASH_ARGV[@]}
                  ((i++))
              done
              echo -e "\033[0m"
              step
  }

  function stepDebugger() {

    if [ "$1" = "OFF" ]; then
        removeTrap
    fi
    if [ "$1" = "ON" ]; then
        export STEP_DEBUG=ON
    fi

  }

  function setTrap() {
    echo "trap DEBUG set to step"
    #export PS4='\033[37m+${LINENO}: \033[0m'
    export PS4='\033[90m+${LINENO}: '
    
    #( trap step DEBUG ) 2>/dev/null
    trap step DEBUG 
 
    #set -e
    trap 'onError ${?}' ERR
    ( trap 'silentOnReturn ${?}' RETURN ) 2>/dev/null
    trap 'onExit  ${?}' EXIT 
  }

  function checkTrace() {
      case $- in
          *x* ) 
              echo "Trace is ON"
              export TRACE=ON
              ;;
          * )               
              echo "Trace is OFF"
              export TRACE=OFF;
              ;;
      esac
  }

  function setTrace() {
      case $TRACE in
          ON ) 
              set -x
              export TRACE=ON
              ;;
          * )               
              set +x
              export TRACE=OFF
              ;;
      esac
  }


  function removeTrap() {
    export STEP_DEBUG=OFF
    #trap - DEBUG ERR RETURN EXIT
  }

  function ckeckDebug() {

    if [[ "$(basename -- "$0")" == "debug" ]]; then
      # called
      if [ -n "$1" ]; then
          DEBUG=$1
      fi
      warn.log "debug has no effect if it was not sourced with . debug"
    else
      # sourced
      echo "debug was sourced from: $0"
      if [[ "$(basename -- "$0")" == "-bash" ]]; then
        debug.log "sourced from: bash"
        DEBUG=$1
      fi
    fi


    if [ -n "$DEBUG" ]; then
      echo "DEBUG was $DEBUG, and is now ON"
      case $DEBUG in
        X)
          set -x
          ;;
        OFF)
          unset DBEUG
          ;;
        *)
          export DEBUG=ON
      esac
    else
      echo "DEBUG is $DEBUG"
    fi
  }

  function toggleDebug() {
      if [ "ON" = "$DEBUG" ]; then 
          DEBUG=OFF
          #set +x
      else
          DEBUG=ON
      fi
      warn.log "Toggeld DEBUG to $DEBUG"
  }

  silentOnReturn() {
    ( { set +x; } 2>/dev/null ; onReturn $@)
  }

  function onReturn() {
      debug.log "function ${FUNCNAME[1]} returned with code: $1 and RETURN=$2"
      if [ "$0" = "$2" ]; then
          #do not stop when in this $0 debug file $2
          return 0
      fi
      
      if [ "ON" = "$STEP_TILL_NEXT_RETURN" ]; then 
          STEP_TILL_NEXT_RETURN=OFF
          export STEP_DEBUG=ON
          #set +x
      fi
  #   if [ -z "$2" ]; then
  #     RETURN=$2
  #   fi
  }

  function onError() {
    #echo -e "\033[1;31m   line: ${BASH_LINENO[2]} '${BASH_COMMAND[2]}'\033[0m"
    if [ "$1" = "1" ]; then
      return
    fi

    error.log         "function ${FUNCNAME[1]} in line: ${BASH_LINENO[2]} returned with ERROR code: $1"
    if [ "ON" = "$DEBUG" ]; then
      export STEP_DEBUG=
      stackTrace
      export STEP_DEBUG=ON
    fi
  }

  function onExit() {
    debug.log "exiting"
  }

  ckeckDebug "$@"

  debug.version
  setTrap
fi









once.discover()             # discovers the environment the current once instance is hosted in
{
  # stepDebugger ON

  if [ -z "$USERHOME" ]; then
    USERHOME=$(cd;pwd)
  fi

  startDir=$(pwd)

  once.isInDocker
  
  echo "Once.discover:
  current shell : $SHELL  (level $(($SHLVL/2)))
          script: $0
          dir   : $startDir
          home  : $USERHOME
        hostname: $HOSTNAME
          type  : $HOSTTYPE
          OS    : $OSTYPE"

  if [[ $startDir =~ "EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once" ]]; then
    stop.log "once.sh started from \$ONCE_DIR: $startDir"
    #once.repair
  fi


  if [ -z "$ONCE_DEFAULT_SCENARIO" ]; then
      #console.log "emergency read once state from user home"
      if [ -f ~/.once ]; then
        source ~/.once
      else
        once.stage not.installed $@

      fi
  fi


  if [ -f $ONCE_DEFAULT_SCENARIO/.once ]; then
	  source $ONCE_DEFAULT_SCENARIO/.once
    echo "          PM    : $ONCE_PM
    "
	  console.log "Once.init with: $ONCE_DEFAULT_SCENARIO/.once"
    once.update.variables
    #console.log "once stage to: $ONCE_STATE"
	  #once.stage $ONCE_STATE 
    stop.log "ONCE_DOMAIN=$ONCE_DOMAIN"
  else
    once stage not.installed $@
    #once.init "$@"
    #once.stage
  fi
  #checkAndFix "is privileged" " ~ = '/root' " "" "ONCE_PRIVILIDGE=root"
}

once.not.installed()
{
        console.log "no .once nor sceanrio discovered: exiting!   ($1)"
        console.log "To INSTALL once please run: once init"
        if [ "$1" = "init" ]; then
          shift
          #stop.log "now going to once.init"
          once.init "$@"
        else
          if [ "$1" = "" ]; then
            rm ~/.once
            exit 1 
          fi
          once.stage $@
          rm ~/.once
          exit 1
        fi
}

once.v()                    # prints out the current version of once - alias for once version 
{
  once.version
}

once.ca()                # checks if and where the simple mkcert Root CA is installed 
{
  # https://github.com/FiloSottile/mkcert
  # https://blog.filippo.io/mkcert-valid-https-certificates-for-localhost/
  once.cmd mkcert 
  if [ -z "CAROOT" ]; then 
    once.ca.install
  fi
  console.log "Root CA installed in: $(mkcert -CAROOT)"
}

function once.mkcert.install() {
  if [ "$ONCE_PM" = "brew" ]; then 
    $ONCE_PM $package
    return
  else
    once.cmd libnss3-tools 
    cd
    wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64
    mv mkcert-v1.4.3-linux-amd64 /usr/local/bin/mkcert
    chmod +x /usr/local/bin/mkcert

  fi

  
}

once.ca.install()         # installs the simple mkcert Root CA
{
  CAROOT=$SCENARIOS_DIR/rootCA/mkcert
  console.log "Installing Root CA mkcert in: $CAROOT"
  export CAROOT
  mkcert -install
  NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
  export NODE_EXTRA_CA_CERTS
  ONCE_EXPORT_NODE_EXTRA_CA_CERTS=$NODE_EXTRA_CA_CERTS
  ONCE_EXPORT_CAROOT=$CAROOT
  
  once.hibernate update
}

once.cu()                  # certifcate update for localhost for the Once Server
{
  once.localhost.certificates
}

once.localhost.certificates() # creates localhost cerifikates for the Once Server
{
  once.ca
  #cd $ONCE_DIR
  cd $ONCE_DEFAULT_SCENARIO
  mkcert -cert-file once.cert.pem -key-file once.key.pem -p12-file once.pfx  server.localhost localhost 127.0.0.1 ::1
}

once.scu()
{
  once.copy.cerbot.certificates "$1"
  shift
  RETURN=$1
}

once.copy.cerbot.certificates()
{
  cd $ONCE_DEFAULT_SCENARIO
  local hostname=$ONCE_DEFAULT_HOST
  if [ -n "$1" ]; then
    console.log "Setting hostname to: $1"
    hostname=$1
    shift
  fi
  checkAndFix "delete once.cert.pem" -f "once.cert.pem" "rm once.cert.pem" 
  checkAndFix "delete once.key.pem" -f "once.key.pem" "rm once.key.pem" 

  checkAndFix "$hostname once.cert.pem" -L "once.cert.pem" "ln -s ../../Docker/CertBot/1.7.0/config/conf/archive/$hostname/cert1.pem once.cert.pem" 
  checkAndFix "$hostname once.key.pem" -L "once.key.pem" "ln -s ../../Docker/CertBot/1.7.0/config/conf/archive/$hostname/privkey1.pem once.key.pem" 
}


function once.repair()      # (CAUTION> not fully tested) should be executed from the ONCE Directory. Will repair settings for the current checked out Repository 
{
    local dir=$1
    if [ -z "$dir" ]; then
      dir=$ONCE_DIR
    else
      shift
    fi
    cd $dir
    console.log "   starting repair mode:"
    console.log "       This: $This
          this: $this
      ONCE_DIR: $dir
           pwd: $(pwd)
    "
    #set -x
    while [ ! $(basename $(pwd)) == "EAMD.ucp" ]; do
      console.log $(basename $(pwd))
      cd ..
    done
    cd ..
    ONCE_REPO_PREFIX=$(pwd)
    console.log "ONCE_REPO_PREFIX: $ONCE_REPO_PREFIX"
    rm -Rf ~/scripts.old
    mv ~/scripts ~/scripts.old
    rm ~/.bashrc
    once.clean up
    cd
    ln -s $ONCE_REPO_PREFIX/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts
    #ln -s ~/scripts/templates/.bashrc
    cp ~/scripts/templates/.bashrc ~/.bashrc

    ONCE_DEFAULT_SCENARIO=
    RETURN=$1
    #cd $ONCE_REPO_PREFIX/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh
    #once.update here
    #exit 0
}


function once.isInDocker()  # checks if the script is executed in a docker container
{
    echo "is in docker?"
    if [ -z "$HOSTNAME" ]; then
      HOSTNAME=$(hostname)
    fi

    if [ -f /.dockerenv ]; then
      console.log "inside of docker"
      ONCE_MODE=IN_DOCKER
      if [ -n "$ONCE_DOCKER_HOST"  ]; then
        console.log "found ONCE_DOCKER_HOST: $ONCE_DOCKER_HOST"
        HOSTNAME=$ONCE_DOCKER_HOST
        console.log "usineg it as HOSTNAME: $HOSTNAME"
      else
        if [ ! "$ONCE_DOMAIN" = ".docker.local" ]; then
          ONCE_DOMAIN=".docker.local"
          if [[ ! $HOSTNAME =~ "$ONCE_DOMAIN" ]]; then
            HOSTNAME=$HOSTNAME$ONCE_DOMAIN
          fi
        fi
      fi
    else
      if [ "$ONCE_MODE" = "IN_DOCKER" ]; then
        ONCE_MODE=DOCKER
      fi
      console.log "  ONCE_MODE=$ONCE_MODE on host $HOSTNAME"
    fi
    #stop.log "ONCE_DOMAIN=$ONCE_DOMAIN"
}


once.help()                 # prints a list of all commands for once
{
  local detail=$1
  if [ -n "$detail" ]; then
    shift
  fi
  grep "^once\.$detail.*()" $This | sort
}

once.superuser()            # prints a list of all the advanced superuser functions in once.sh
{
  local detail=$1
  if [ -n "$detail" ]; then
    shift
  fi
  console.log "This are the advanced funtions for superusers in $This:"
  grep "^function once\.$detail.*()" $This | sort
  #exit 0
}
once.su()                   # alias to once.superuser to list advanced functions ot $This
{
  once.superuser
}

function checkAndFix()      # checkes and fixing/adding files
{
    debug.log "checkAndFix(1:$1 2:$2 3:$3 4:$4  silent:$5)"
    if [ $2 "$3" ]; then
        if [ -z "$5" ]; then
    	    echo "check: ok     : $1: $3"
        fi
    else
        if [ -z "$5" ]; then
          echo "check: failed : $1: $3        ...fixing with: $4"
        fi
        $4
    fi
}




once.cmd()                  # checks if the <command> is available or is being installed via the package manager in $ONCE_PM, if the package name is diffrent it can be specify with e.g. once cmd ssh openssl 
{

    current=$1
    shift
    package=$1
    shift

    if [ -z "$package" ]; then
        package=$current
    else
      shift
      package=$1
    fi   

    if [ -z "$ONCE_PM" ]; then
      console.log "no PM found...checking" 
      once.check.all.pm
    fi
    if ! [ -x "$(command -v $current)" ]; then
        console.log "no $current"
        if [ -n "$ONCE_PM" ]; then
          case $current in
            eamd)
              once.load $current tla/EAMD/UcpComponentSupport/1.0.0/src/sh/eamd
              hash -d eamd    #clears the command cache for eamd
              #hash -r   #clears the command cache completley
              ;;
            oosh)
              once.load $current com/ceruleanCircle/EAM/1_infrastructure/OOSH/1.0.0/src/sh/oosh
              ;;
            once)
              once.load once.sh tla/EAM/layer1/Thinglish/Once/latestServer/src/sh/once.sh
              cd $ONCE_LOAD_DIR
              mv once.sh once
              once.stage status
              ;;
            npm)
              once.npm.install
              ;;
            mkcert)
              once.mkcert.install
              ;;
            *)
              $ONCE_PM $package
            esac
        else
            console.log "no package manger"
        fi
        shift
    fi
    RETURN=$1
}
once.load()                 # loads ONCE Object Oriented SHell components (scripts) e.g: once load paths
{

  #set -x
  echo load $1
  ONCE_LOAD_DIR=$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer/oosh
  once.path.create $ONCE_LOAD_DIR
  cd $ONCE_LOAD_DIR/
  if [ -f "$1" ]; then
    rm $1.*
    console.log "WARNING: the file is already downloaded: $ONCE_LOAD_DIR/$1"
    console.log "Please add it to the PATH with running:   . once path"
  else
    #once.path
    once.cmd wget
    local url=$ONCE_DEFAULT_URL
    if [ -n "$ONCE_LOCAL_SERVER" ]; then
      url=$ONCE_LOCAL_SERVER
    fi

    wget $url/$ONCE_REPO_NAME/$ONCE_REPO_COMPONENTS/$2
    chmod 744 $1
    #set +x
    #once.stage done
  fi
}

function once.npm.install() 
{
      curl -sL https://deb.nodesource.com/setup_16.x | bash -
      $ONCE_PM nodejs
      once.npm.update.shell
}

function once.npm.update.shell()      # updates the shell used bey npm to /bin/bash    (on trouble with '. .once' or 'source .once' )
{
  npm config set script-shell /bin/bash
} 


function once.check.pm()             # checks for a package manager
{

    local packageManager=$1
    local packageManagerCommand=$2


    if [ -z "$packageManagerCommand" ]; then
        package=$packageManager
    fi   
    if ! [ -x "$(command -v $packageManager)" ]; then
        debug.log "no $packageManager"
    else
        if [ -z "$ONCE_PM" ]; then
            export ONCE_PM=$packageManagerCommand
            export groupAddCommand=$3
            export userAddCommand=$4
            echo "Package Manager found: using $ONCE_PM somePackage"
            if [ "$packageManager" = "apt-get" ]; then
                if [ -z "$ONCE_PM_UPDATED" ]; then
                  ONCE_PM_UPDATED="apt-get update"
                  if [ "$ONCE_PRIVILEGE" = root ]; then
                    $ONCE_PM_UPDATED
                  else 
                    PM="sudo $PM"
                  fi
                else
                  echo "in case of installation errors try to call: apt-get update"
                fi
            fi
        fi
    fi
}
function once.check.all.pm()         # adds tools and configurations to package manager (brew, apt-get, addgroup, adduser, dpkg, pkg)
{

    once.check.pm brew "brew install"    
    #once.check.pm apt "apt add"
    once.check.pm apt-get "apt-get -y install" "groupadd -f" "useradd -g dev"
    once.check.pm apk "apk add" "addgroup" "adduser -g dev"
    once.check.pm dpkg "dpkg install"
    once.check.pm pkg "pkg install"
    once.check.pm pacman "pacman -S"

 
}
function once.pm()                   # calls package manager 
{

  ONCE_PM=
  once.check.all.pm
  console.log "PM: $ONCE_PM"

  RETURN=$1
}


once.scenario.check()     # prints out the current set scenario without changing it
{
  if [ -z "$ONCE_DEFAULT_SCENARIO" ]; then
    console.log "Setting ONCE_DEFAULT_SCENARIO to: $SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer"
    export ONCE_DEFAULT_SCENARIO=$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer
    once.hibernate update
  else
    console.log "Current ONCE_DEFAULT_SCENARIO is: $ONCE_DEFAULT_SCENARIO"
    console.log "        ONCE_SCENARIO         is: $ONCE_SCENARIO"
  fi
}

once.scenario.fix()        # if the scenario is not correct you can force it to update with this command. First parameter is the optional domain e.g. test.wo-da.de
{
  once.scenario.check

  once.scenario $1
  if [ -n "ONCE_SCENARIO" ]; then
      ONCE_SCENARIO=$SCENARIOS_DIR/$(cat $ONCE_DEFAULT_SCENARIO/once.scenario)
  fi 
  stop.log    "NEW current ONCE_DEFAULT_SCENARIO is: $ONCE_DEFAULT_SCENARIO"
  console.log "                   ONCE_SCENARIO         is: $ONCE_SCENARIO"
  once.update.variables
  once.hibernate update
}

once.scenario()             # forces re-discovery of the current environment and scenario configuration, but does not change settings (use scenario.fix to change settings) 
{
  once.cmd eamd
  #once.path

  cd $ONCE_DEFAULT_SCENARIO
  local hostname=$HOSTNAME
  if [ -n "$1" ]; then
    console.log "Setting hostname to: $1"
    hostname=$1
    shift
  fi
  debug.log h:$hostname- H:$HOSTNAME-
  #stepDebugger ON

  eamd call loop $hostname . reverse x log . r / save once.scenario
  ONCE_SCENARIO=$SCENARIOS_DIR/$(cat once.scenario)
  console.log "ONCE_SCENARIO=$ONCE_SCENARIO"
  ONCE_DOMAIN=$(find $ONCE_SCENARIO -type d -name CertBot -exec find {}/1.7.0/config -mindepth 1 -maxdepth 1 -type d \;)
  #console.log "-ONCE_DOMAIN=-$ONCE_DOMAIN-"
  if [ -n "$ONCE_DOMAIN" ]; then
    stop.log "found domain ONCE_DOMAIN=$ONCE_DOMAIN"
    eamd call loop $ONCE_DOMAIN / silent x result $startDir/.tmp.result.list.env
    . $startDir/.tmp.result.list.env
    ONCE_DOMAIN=$lastItem
    
    #ONCE_DEFAULT_SERVER=$ONCE_DOMAIN
    ONCE_DEFAULT_HOST=$ONCE_DOMAIN
    
    console.log "ONCE_DOMAIN=$ONCE_DOMAIN"
    eamd call loop $ONCE_DOMAIN . reverse x log . r / save once.domain
    ONCE_DOMAIN=$(cat once.domain)
    ONCE_SCENARIO=$ONCE_SCENARIO/vhosts/$ONCE_DOMAIN

    console.log "ONCE_SCENARIO=$ONCE_SCENARIO"
    rm once.scenario
    rm $startDir/.tmp.result.list.env
    rm once.domain
    tree $ONCE_DEFAULT_SCENARIO
  fi
  stop.log "new ONCE_SCENARIO=$ONCE_SCENARIO"
  ONCE_DEFAULT_SCENARIO=$ONCE_SCENARIO/EAM/1_infrastructure/Once/latestServer
  checkAndFix  "default ONCE_DEFAULT_SCENARIO location" "-d" "$ONCE_DEFAULT_SCENARIO" "once.path.create $ONCE_DEFAULT_SCENARIO"
  checkAndFix  "checking if .once.env link exist" "-L" "$ONCE_DEFAULT_SCENARIO/.once.env" "ln -s $ONCE_DEFAULT_SCENARIO/.once $ONCE_DEFAULT_SCENARIO/.once.env"
  
  #once.paths.reset
  #once.paths.save

}

function once.find()                 # finds all running node servers
{
  ps aux | grep Once
}

function once.check.installation()   # checks for a once installation in given path
{

  checkAndFix "exists $ONCE_REPO_PREFIX" "-d" "$ONCE_REPO_PREFIX" "once.path.create $ONCE_REPO_PREFIX"

  once.pm
  checkAndFix "make once alias $(which $0)" -L "$(dirname $(which $0))/once" "ln -s $(which $0) $(dirname $(which $0))/once" 
  once.cmd wget
  once.cmd curl
  once.cmd git
  once.cmd eamd

  once.stage ssh.init


  if [ -d $COMPONENTS_DIR ]; then
    console.log "Repository found at $COMPONENTS_DIR..."
    console.log "discover scenario..."
    once.stage scenario
    #once paths.reset paths.save
  else
    console.log "Repository NOT FOUND at $COMPONENTS_DIR..."
    once.stage repo.init

  fi
  
  once.stage installed
}

function once.installed()            # prints where the repository has been installed 
{

  console.log "Repository is installed at: $ONCE_REPO_PREFIX/$ONCE_REPO_NAME"
  once.stage server.start
}

function once.build.successful() 
{
  console.log "BUILD successfull, not starting once"
}

# function once.startlog() 
# {
#   once.server.start
#   once.log
# }  

function once.server.start()         # starts the once server if not already up and running
{
  once.isInDocker
  console.log "once start in mode $ONCE_MODE with option $@"

  if [ "$ONCE_BUILD" = "BUILDING" ]; then
    unset ONCE_BUILD
    once.stage build.successful
    exit 0
  fi

  if [ "$ONCE_MODE" = "IN_DOCKER" ]; then
    if [ -f /.dockerenv ]; then
      once.server.start.inDocker
      return
    else
      once.server.start.docker
      return
    fi
  fi

  if [ "$ONCE_MODE" = "DOCKER" ]; then
    once.server.start.docker
    return
  fi

  if [ "$ONCE_MODE" = "LOCAL" ]; then
    once.server.start.local "$@"
    return
  fi

  err.log "UNKNOWN ONCE_MODE: $ONCE_MODE"
  
}

function once.server.start.local()
{
  if [ "$1" = "start" ]; then 
    shift
    RETURN=$1
  fi

  if [ -n "$ONCE_SERVER_PID" ]; then
    if [ "$1" != "new" ]; then  
      console.log "Server is already up: $ONCE_SERVER_PID";
      once.cat
      shift
      RETURN=$1
      return 
    fi
  fi 
  once.cmd npm

  cd $ONCE_DIR
  console.log "Starting Once Server in: $(pwd)"
  console.log "   option: $@"

  if [ "$1" != "fast" ]; then 
    npm update
  else 
    shift
  fi
    
  nohup node -r dotenv/config src/js/Once.class.js dotenv_config_path=$ONCE_DEFAULT_SCENARIO/.once.env &>$ONCE_DEFAULT_SCENARIO/once.log &

  ONCE_STATE=state
  ONCE_SERVER_PID="$ONCE_SERVER_PID $!"
  once.hibernate update

  console.log "Once Server up as PID: $ONCE_SERVER_PID"
  RETURN=$1
}
function once.server.start.docker()
{
  cd $COMPONENTS_DIR/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Nodejs/14
  console.log "Starting Once Server in: $(pwd)"
  runDocker
}
function once.server.start.inDocker()
{
  once.server.start.local
}

function once.server.stop()          # stops the server 
{
  once.isInDocker
  console.log "once stop in mode $ONCE_MODE"

  if [ "$ONCE_MODE" = "IN_DOCKER" ]; then
    if [ -f /.dockerenv ]; then
      once.server.stop.process 
      return
    else
      once.server.stop.docker
      return
    fi
  fi

  if [ "$ONCE_MODE" = "DOCKER" ]; then
    once.server.stop.docker
    return
  fi

  if [ "$ONCE_MODE" = "LOCAL" ]; then
    once.server.stop.process $@
    return
  fi

  err.log "UNKNOWN ONCE_MODE: $ONCE_MODE"


}

function once.server.stop.docker()   
{
  cd $COMPONENTS_DIR/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Nodejs/14
  console.log "stoping Once Server Docker Container from: $(pwd)"
  docker-compose stop
}

function once.server.stop.process()          # stops the server 
{
  if [ -n "$1" ]; then
    console.log "Setting Once Server PID to: $1"
    ONCE_SERVER_PID=$1
  fi
  console.log "Stopping Once Server with PID: $ONCE_SERVER_PID"
  
  kill -SIGTERM $ONCE_SERVER_PID
  
  ONCE_STATE=check.installation
  ONCE_SERVER_PID=
  once.hibernate update
}
once.state()                # lists the current state of the once server and the current configuration alias to once state 
{

  once.version
  console.log "read state from ONCE_DEFAULT_SCENARIO: $ONCE_DEFAULT_SCENARIO
  "
  cat $ONCE_DEFAULT_SCENARIO/.once
  once.config.list

  if [ -n "$ONCE_SERVER_PID" ]; then
    console.log "EOF

  Once Server is up.
    Stop      it with: $0 stop <?PID:$ONCE_SERVER_PID>
    Log       it with: $0 log
    Get Log file with: $0 cat
    "
  else
    console.log "EOF

  Once Server is down...
    ";
  fi
}

once.server()
{
    if [ -z "$1" ]; then 
        tree -L 1 $ONCE_DIR/..
        return
    fi

    cd $ONCE_DIR/..
    local version=$1
    if [ -d $version ]; then
      checkAndFix "remove latestServer"  "! -L" "latestServer" "rm latestServer"
      checkAndFix "set    latestServer"  "-d" "latestServer" "ln -s $version latestServer"
      ONCE_DIR=$COMPONENTS_DIR/tla/EAM/layer1/Thinglish/Once/$version
      once.update.variables
      tree -L 1 $ONCE_DIR/..
      once.stage done
    else
      err.log "Once Version $version not found"
    fi

}

once.client()
{
    if [ -z "$1" ]; then 
        tree -L 1 $ONCE_DIR/..
        return
    fi

    cd $ONCE_DIR/..
    local version=$1
    if [ -d $version ]; then
      checkAndFix "remove latestClient"  "! -L" "latestClient" "rm latestClient"
      checkAndFix "set    latestClient"  "-d" "latestClient" "ln -s $version latestClient"
      tree -L 1 $ONCE_DIR/..
      once.stage done
    else
      err.log "Once Version $version not found"
    fi

}

function once.check.privileges()     # checks the administrative rights of the current once instance 
{

  if [ "$USERHOME" != "/root" ]; then
    once.stage user
  else
    once.stage root
  fi
  once.update.variables
  once.hibernate update

  once.stage
}

function once.root()                 # populates the environmental variables with root administrative rights 
{
    ONCE_PRIVILEGE=root
    ONCE_REPO_PREFIX=/var/dev
    ONCE_STATE=root.installation
}

function once.root.installation()    # installs the repo as root user
{
  once.check.installation
}

function once.user()                 # populates the environmental variables with user administrative rights 
{
    ONCE_PRIVILEGE=user
    ONCE_REPO_PREFIX=$USERHOME/dev
    ONCE_STATE=user.installation
    if [ -z "ONCE_SUDO" ]; then 
      ONCE_SUDO="sudo"
    fi
    ONCE_PM="sudo $ONCE_PM"

}

once.user.developer() 
{
  if [ -d $REPO_DIR ]; then
    once.user.discover
    case $custom_uid in
      root)
        warn.log "$REPO_DIR is owned by root"
        ;;
      developer)
        warn.log "user developer already exists"
        ;;
      ''|*[!0-9]*)
        warn.log "custom_uid is not a number: uid=$custom_uid gid=$custom_gid"
        ;;
      *)
        #groupadd dev
        once.user.create developer $custom_uid $custom_gid
        ;;
    esac
  else
    warn.log "Repository does not exist: $REPO_DIR"
  fi
}

once.user.init()
{
    local username=$1
    shift
    if [ -d /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts ]; then
      $ONCE_SUDO usermod -a -G sudo $name
      #useradd -g dev $name 
      cd /home/$name
      $ONCE_SUDO cp /root/.bashrc /home/$name/.bashrc
      $ONCE_SUDO chown $name:$name /home/$name/.bashrc
      
      $ONCE_SUDO cp /root/.once /home/$name/.once
      $ONCE_SUDO chown $name:$name /home/$name/.once

      ln -s /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts
      $ONCE_SUDO chown -h $name:$name /home/$name/scripts
        $ONCE_SUDO cp /root/.once /home/$name/.once
      if [ -d /home/$name/.ssh ]; then
        if [ "$name" = "develo[er" ]; then
          $ONCE_SUDO cp -r /home/$name/scripts/templates/developking.ssh /home/$name/.ssh
          $ONCE_SUDO chown $name:$name /home/$name/.ssh
        else
          warn.log "use   scripts/ssh.init  to create keys"
        fi
      fi

    else
      local userHome="/home/$name"

      if [ ! -d "$userHome/scripts" ]; then
          warn.log "$userHome/scripts does not exist..."
          console.log "creating $userHome/scripts"
          #git clone cerulean.it/var/dev/GIT/scripts.git
          once.cmd wget
          once.cmd unzip
          rm scripts.zip*
          debug.log "wget http://test.wo-da.de/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts.zip"
          wget http://test.wo-da.de/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts.zip
          unzip scripts.zip -d $userHome/
          chmod +x -R $userHome/scripts
          #cp $eamdDir/eamd $userHome/scripts
          # chown -R $user:dev $userHome
          # chown -R $user:dev $userHome/.*
          chown -R $name:dev $userHome/scripts/*
          chsh -s $(which bash) $name
      else
          cd $userHome/scripts
          checkCommand git
          git pull
          #git clone $defaultGitUser@$defaultGitServer:/home/dev/GIT/scripts.git
      fi



      if [ ! -w "$userHome/.bashrc" ]; then
          warn.log "$userHome/.bashrc does not exist..."
          console.log "creating it..."
          cp $userHome/scripts/templates/.bashrc $userHome
          if [ ! -w "$userHome/.profile" ]; then
              #touch $userHome/.profile
              ln -s .bashrc .profile
              chmod +x $userHome/.bashrc
          fi
          #link for mac osx
          ln -s .bashrc .bash_profile
          . $userHome/.bashrc
      else
          if [ -w $userHome/scripts/templates/bashrc_addonTemplate ]; then
              #console.log "improving .bashrc"
              #cat $userHome/scripts/templates/bashrc_addonTemplate >>$userHome/.bashrc
              #rm $userHome/scripts/templates/bashrc_addonTemplate
              warn.log "prevented bash enhancement"
          else 
              console.log ".bashrc already improved"
          fi
      fi
    fi

}

once.user.create()                   # expets name <uid gid> and creates a new user with home dir
{

  local name=$1
  local custom_uid=
  local custom_gid=
  shift
  if [ -n "$1" ]; then
    custom_uid=$1
    shift
  fi
  if [ -n "$1" ]; then
    custom_gid=$1
    shift
  fi

  if [ -n "$custom_uid" ]; then
    $ONCE_SUDO useradd -m $name -u$custom_uid -g$custom_gid -s /bin/bash
  else
    $ONCE_SUDO useradd -m $name -s /bin/bash
  fi
  $ONCE_SUDO usermod -aG sudo $name
  #useradd -g dev $name 
  once.user.init $name
  

  RETURN=$1

}

function once.user.discover()
{
  cd $REPO_DIR
  local filename=check.user.txt
  touch $filename
  custom_uid=$(ls -al $REPO_DIR/$filename | cut -f 3 -d ' ')
  custom_gid=$(ls -al $REPO_DIR/$filename | cut -f 4 -d ' ')

  console.log "discoverd UID: $custom_uid   and GID: $custom_gid"
  #rm $filename
}

function once.user.installation()    # installs the repo as a user
{
  if [ -d /var/dev ]; then
      ONCE_REPO_PREFIX=/var/dev
  fi
  once.check.installation
}


function once.group.discover.id()   # finds the custom_gid for a group name
{
  local groupname=$1
  shift
  local ginfo=$( getent group $groupname )
  console.log "found group info: $ginfo"
  custom_gid=$(cut -d: -f3 <(echo $ginfo))
  console.log "discovered custom_gid=$custom_gid"
  RETURN=$1
}

function once.group.discover.id()   # finds the custom_gid for a group name
{
  local groupname=$1
  shift
  once.group.discover.id $groupname

  RETURN=$1
}

function once.path.create()          # creates respective paths
{

    console.log " function ${FUNCNAME[0]}($1) $@"


    if [[ "$1" = /* ]]; then
        cd "/"
    fi

    path=""
    console.log "creating path in $(pwd)"

    for current in ${1//// }; do

        if [ -z "$path" ]; then
            path=$current
        else
            path=$path/$current
        fi
        debug.log "checking path: $path"

        once.createDir $path
    done
}

function once.createDir()            # creates respective directory requested in parameter 
{

    local current=$1
    if [ ! -d $current ]; then
        debug.log "$current does not exist: creating it..."
        mkdir -p $current
    fi
}

function once.ssh.init() 
{
  once.path
  rm scripts.zip*
  
  eamd v
  #stepDebugger ON

  
  if [ ! "$?" = "0" ]; then
    exit $?
  fi
  
  if [ ! -f "~/.ssh/id_rsa" ]; then
    eamd oinit ssh
  fi
}

function once.repo.init()            # forces reinitialisation 
{

  console.log "initialize Repository in $ONCE_REPO_PREFIX"
  cd $ONCE_REPO_PREFIX
  #checkAndFix  "default $ONCE_REPO_PREFIX Repository location" "-d" "$ONCE_REPO_PREFIX" "once path.create $ONCE_REPO_PREFIX"
  #checkAndFix  "default $ONCE_REPO_NAME Repository location" "-d" "$COMPONENTS_DIR" "once path.create $COMPONENTS_DIR"
  #checkAndFix  "default $ONCE_REPO_NAME Repository location" "-d" "$COMPONENTS_DIR" "once path.create $COMPONENTS_DIR"
  #checkAndFix  "default ONCE_DEFAULT_SCENARIO location" "-d" "$ONCE_DEFAULT_SCENARIO" "once path.create $ONCE_DEFAULT_SCENARIO"

  eamd oinit components

  tree -L 2 /var/dev
  stop.log "after clone"

  mv $ONCE_REPO_PREFIX/Backup.$ONCE_REPO_NAME/$ONCE_REPO_SCENARIOS $ONCE_REPO_PREFIX/$ONCE_REPO_NAME.previous
  rmdir $ONCE_REPO_PREFIX/$ONCE_REPO_NAME
  mv $ONCE_REPO_PREFIX/$ONCE_REPO_NAME.previous $ONCE_REPO_PREFIX/$ONCE_REPO_NAME
  rm ~/scripts/eamd
  
  cd $ONCE_REPO_PREFIX/$ONCE_REPO_NAME
  git config --global user.email "freemiumuser@example.com"
  git config --global user.name "freemium user"
  git stash -u 
  git checkout -t origin/$ONCE_SCENARIO_BRANCH
  # mv $ONCE_REPO_PREFIX/$ONCE_REPO_NAME/Scenarios/localhost/ /var/dev/EAMD.backup/
  checkAndFix  "default ONCE_DEFAULT_SCENARIO location" "-d" "$ONCE_LOAD_DIR" "once.path.create $ONCE_LOAD_DIR"
  # stop.log "fix /Scenarios/localhost"
  # mv /var/dev/EAMD.backup/ $ONCE_REPO_PREFIX/$ONCE_REPO_NAME/Scenarios/
  # rmdir $ONCE_REPO_PREFIX/Backup.$ONCE_REPO_NAME


  if [ "$ONCE_PRIVILEGE" = "root" ]; then
    console.log "root privileges detected...: fixing group rights on repository"
    chown -R $USER:dev $ONCE_REPO_PREFIX
    chmod -R g+wx $ONCE_REPO_PREFIX
    ls -alF $ONCE_REPO_PREFIX
    console.log "    done"
  fi
  
  once.stage scenario.fix
}

once.log()                  # opens the once log file and continues monitoring 
{

  tail -f $ONCE_DEFAULT_SCENARIO/once.log
  once.done
}

once.cat()                  # prints the current once log file to the console and exits 
{

      cat $ONCE_DEFAULT_SCENARIO/once.log
      once.done
}
once.status()               # lists the current state of the once server and the current configuration alias to once state 
{

  once.state "$@"
}

once.stop()                 # stops the server... if $ONCE_PID is wrong it can be overwritten by specifying the optional PID parameter  
{

  once.server.stop "$@"
}

function once.list.www()             # tries to find domain configurations on the current server location 
{

  #tree -dL 2 /var/www
  #find $SCENARIOS_DIR -type d -name CertBot -exec tree -d {}/1.7.0/config \;
  console.log $HOSTNAME
  find $SCENARIOS_DIR -type d -name CertBot -exec find {}/1.7.0/config -mindepth 1 -maxdepth 1 -type d  \;
  once.done
}

once.path()                 # sets the path to the scripts to be loaded by once as well the sources of the $ONCE_ environment variables  
{

  checkAndFix  "default ONCE_LOAD_DIR location" "-d" "$ONCE_LOAD_DIR" "once.path.create $ONCE_LOAD_DIR"
  #once.cmd eamd
  if [ -z "$ONCE_PATHS" ]; then 
    stop.log "about to reset path"
    once.paths.reset

    console.log "exported PATH: $PATH
    make sure you called this command as ". $this path"
    "

    ONCE_PATHS=$ONCE_DEFAULT_SCENARIO/paths
    checkAndFix "set ONCE_SHELL_RC: $ONCE_SHELL_RC" "-n" "$ONCE_SHELL_RC" "export ONCE_SHELL_RC=$HOME/.$(basename $SHELL)rc"
    
    echo "
    echo load path configuration for once:
    source ~/.once
 
    #cat ~/.once
    ONCE_PATHS=$ONCE_DEFAULT_SCENARIO/paths
    echo ' 
    
    Welcome to Web 4.0
    
    '
    " >>$ONCE_SHELL_RC
    ONCE_PATHS=$ONCE_DEFAULT_SCENARIO/paths
    hash -r ## rescan PATH
    NEW=" entering $ONCE_SHELL"

    once.hibernate update
  else
    console.log "PATH will be loaded from $ONCE_PATHS"
    console.log "current PATH=$PATH"
  fi

  #once.done
}

function once.paths.reset()                # reset path 
{
    ONCE_PATHS=
    PATH=.:~/scripts:$ONCE_INITIAL_PATH:$ONCE_DEFAULT_SCENARIO/oosh/:\$ONCE_REPO_PREFIX/\$ONCE_REPO_NAME/\$ONCE_REPO_COMPONENTS/com/ceruleanCircle/EAM/1_infrastructure/OOSH/1.0.0/src/sh:$ONCE_LOAD_DIR:\$ONCE_REPO_PREFIX/\$ONCE_REPO_NAME/\$ONCE_REPO_COMPONENTS/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts
    export PATH
    console.log "reset path to: PATH=$PATH"
    once.update.variables
    once.hibernate update
}

once.clean()                # uninstalls once and removes the current .once configuration. Afterwards once.sh has to be used to reinstall
                            # removes all .once configurations from all scenarios
{

  rm ~/.once
  rm $ONCE_DEFAULT_SCENARIO/.once
  #mv $ONCE_DEFAULT_SCENARIO/paths $ONCE_DEFAULT_SCENARIO/paths.bak
  #rm ~/scripts/eamd
  local this=$0
  checkAndFix "remove once alias $this" "! -L" "$(dirname $this)/once" "rm $(dirname $this)/once" 
  rm -Rf $ONCE_LOAD_DIR
  if [ "$1" = "all" ]; then
    console.log "force deleting $SCENARIOS_DIR"
    rm -Rf $SCENARIOS_DIR
  fi
  
  if [ "$1" = "remove" ]; then
    console.log "force cleaning all environments"
    find $SCENARIOS_DIR -name .once -print
    find $SCENARIOS_DIR -name .once -exec rm {} \;
    find $SCENARIOS_DIR -name paths -exec rm {} \;
  fi
  
  if [ ! "$1" = "up" ]; then 
    exit 0 
  fi
}

once.config()               # starts vim to edit the current .once config 
{
  once.cmd vim
  vim $ONCE_DEFAULT_SCENARIO/.once
  once.update.variables
  once.config.list

  once.unset
}

once.config.list()          # prints a list of configurations (COMPONENTS_DIR, REPO_DIR, SCENARIOS_DIR, ONCE_DIR, ONCE_DEFAULT_SCENARIO, ONCE_LOAD_DIR)
{
  echo COMPONENTS_DIR=$REPO_DIR/$ONCE_REPO_COMPONENTS
  echo REPO_DIR=$ONCE_REPO_PREFIX/$ONCE_REPO_NAME
  echo SCENARIOS_DIR=$REPO_DIR/$ONCE_REPO_SCENARIOS
  echo ONCE_DIR=$COMPONENTS_DIR/tla/EAM/layer1/Thinglish/Once/latestServer
  echo ONCE_DEFAULT_SCENARIO=$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer
  echo ONCE_LOAD_DIR=$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer/oosh
  echo PATH=$PATH
}

once.edit()                 # starts vim to edit the once script
{

  once.cmd vim
  vim $ONCE_DIR/src/sh/once.sh
}

once.code()                 # starts vim to edit the Once.class.js Kernel 
{

  once.cmd vim
  vim $ONCE_DIR/src/js/Once.class.sh
}


once.update()               # updates a git pull on the repository to get all the newest versions
                            # updates fromBranch <?origin> updates the current branch from origin: e.g. once update fromBranch origin/test/sprint12
                            # updates cmd <command> updates the command 
{

  #set -x
  local command=$1
  if [ -z "$command" ]; then
    shift
  fi

  local branch=$1
  if [ -z "$branch" ]; then
    shift
  fi
  case $command in
    byIP)
      scp ~/scripts/once.sh root@$ONCE_DEFAULT_SSH_IP:/root
      ;;
    server)
      scp ~/scripts/once.sh root@$ONCE_DEFAULT_HOST:/root
      #scp ~/scripts/once.sh root@$ONCE_DEFAULT_HOST:$COMPONENTS_DIR/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh/once.sh
      #scp ~/scripts/once.sh root@$ONCE_DEFAULT_HOST:$COMPONENTS_DIR/tla/EAM/layer1/Thinglish/Once/4.0.0/src/sh/once.sh
      #scp ~/scripts/once.sh root@$ONCE_DEFAULT_HOST:$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/4.0.0/oosh/once
      ;;
    here)
      #set -x
      shift
      local url=$1
      if [ -z "$url" ]; then
        url=$ONCE_LOCAL_SERVER
      fi
      if [ -z "$url" ]; then
        url=$ONCE_DEFAULT_URL
      fi
      rm ./once.sh
      wget $url/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh/once.sh
      chmod +x ./once.sh
      cp ./once.sh $ONCE_REPO_PREFIX/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh
      #scp root@$ONCE_DEFAULT_HOST:/root/once.sh ./once.sh
      #pushd $ONCE_REPO_PREFIX/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh
      rm ~/once.sh
      rm ~/once
      exit 0
      ;;
    root)
      scp root@$ONCE_DEFAULT_SSH_IP:/root/once.sh ~/scripts/once.sh
      ;;
    fromBranch)
      once.update.fromBranch $branch 
      set +x
      exit 0
      ;;
    cmd)
      rm $(which $branch)
      once.cmd $branch
      ;;
    *)
      #once.cmd once
      cd $REPO_DIR
      currentBranch=$(git rev-parse --abbrev-ref HEAD)
      if [ "$ONCE_LATEST_BRANCH" = "$currentBranch" ]; then
        console.log "once update by: git pull"
        git pull
      else
        console.log "once update by: git merge origin/$ONCE_LATEST_BRANCH"

        once.update.fromBranch $ONCE_LATEST_BRANCH
      fi
      ;;
  esac
  
  set +x
  RETURN=$1
  once.done
}

function once.update.fromBranch()
{ 
      # @TODO double check if ONCE_SCENARIO_BRANCH contains the word Scenario
      local branch=$1
      once.cmd git
      shift
      cd $REPO_DIR
      git pull
      #git reset HEAD --hard
      #git clean -fdx
      git stash -u save once.update $(date)
      echo execute: git merge origin/$branch
      git merge origin/$branch
      # @TODO check SCENARIO_BRANCH ist nicht der gleiche wie $1 (LATEST_BRANCH)

      #git push
      once.stage done
} 

function  once.done()                 # finalising script execution in a clean process
{
	ONCE_STATE=state
  once.hibernate update
  console.log "once.sh: done $NEW"
  if [ -n "$NEW" ]; then
    cd ~
    scripts/once.sh links.fix
    $ONCE_REPO_PREFIX/$ONCE_REPO_NAME/$ONCE_REPO_COMPONENTS/com/ceruleanCircle/EAM/1_infrastructure/NewUserStuff/scripts/once.sh links.fix
    #clear
    NEW=
    $ONCE_SHELL -c ". ~/.bashrc; once status; $SHELL"
  fi
  exit 0
}

function once.i() 
{
  once.interactive "$@"
}
function once.interactive() {
  stepDebugger ON
  RETURN=$1
}

once.env()                  # lists the current $PATH paths on the screen 
{
  once cmd vim
  vim ~/.once
  RETURN=$1
}

once.paths.save()           # saves the current $PATH into the file in $ONCE_DEFAULT_SCENARIO/paths 
{
  cd $ONCE_DEFAULT_SCENARIO
  rm paths
  eamd call loop $PATH : call echo "paths"
}

once.paths.list()           # printing list of paths 
{
  cat $ONCE_DEFAULT_SCENARIO/paths
}

once.paths.edit()           # manually edit paths with vim
{
  vim $ONCE_DEFAULT_SCENARIO/paths
}

once.paths.load()           # loading all paths
{
    if [ ! -f $ONCE_DEFAULT_SCENARIO/paths ]; then
      console.log "$ONCE_DEFAULT_SCENARIO/paths not found!!!"
      once.paths.reset
      once.paths.save
      once.scenario
      return
    fi

    PATH=
    while read line; do
      if [ -n "$PATH" ]; then
        PATH=$PATH:$line
      else
        PATH=$line
      fi
    done <$ONCE_DEFAULT_SCENARIO/paths
    export PATH
    echo $PATH
}


function once.mv()                   # to be deleted: moves the Repo prefix...just a test 
{

  REPO_PREFIX_UNDO=$ONCE_REPO_PREFIX
  if [ -n "$1" ]; then
    ONCE_REPO_PREFIX=$1
  fi
  once.update.variables
  once.config.list
  echo
  echo REPO_PREFIX_UNDO=$REPO_PREFIX_UNDO
}

once.links.fix()            # checks that the once and once.sh are links to the latest files after repo.init
{
  local DIR=$(dirname $This)
  if [ "$DIR" = "." ]; then
    DIR=$startDir
  fi

  if [ "$DIR" = "$ONCE_DIR/src/sh" ]; then
    DIR=/usr/local/sbin
  fi

  if [ "$DIR" = "/usr/local/sbin" ]; then
    console.log "once not yet installed but mapped to /usr/local/sbin  ...  $This ... $(dirname $This)... nothing changed!"
  else
    checkAndFix "make once.sh a live link into the repository $This" -L "$(dirname $This)/once.sh" "links.fix" 
    once.links
  fi

}
function links.fix()        # checks that the once and once.sh are links to the latest files after repo.init
{
  local DIR=$(dirname $This)
  if [ "$DIR" = "$ONCE_DIR/src/sh" ]; then
    err.log "Cannot fix links in $DIR"
    return
  fi
  #rm $DIR/once.sh
  rm $DIR/once*
  rm $DIR/eamd*
  rm /var/dev/EAMD.ucp/Scenarios/localhost/EAM/1_infrastructure/Once/latestServer/oosh/eamd*
  ln -s /var/dev/EAMD.ucp/Components/tla/EAMD/UcpComponentSupport/1.0.0/src/sh/eamd /var/dev/EAMD.ucp/Scenarios/localhost/EAM/1_infrastructure/Once/latestServer/oosh/eamd
  ln -s /var/dev/EAMD.ucp/Components/tla/EAMD/UcpComponentSupport/1.0.0/src/sh/eamd $DIR/eamd
  ln -s $ONCE_DIR/src/sh/once.sh $DIR/once.sh
  pushd .
  cd $DIR
  ln -s ./once.sh once
  popd
}

once.links()                  # lists the most important links
{
    local DIR=~/scripts
    which once
    ls -alF $DIR/once*
    which eamd
    ls -alF $DIR/eamd*
}

function once.links.replace() # replace the once links by a hardcopy of the latest version form the repo
{
  local DIR=$(dirname $This)
  if [ "$DIR" = "." ]; then
    DIR=$startDir
  fi

  if [ "$DIR" = "$ONCE_DIR/src/sh" ]; then
    DIR=/usr/local/sbin
  fi

  if [ "$DIR" = "/usr/local/sbin" ]; then
    console.log "once not yet installed but mapped to /usr/local/sbin  ...  $This ... $(dirname $This) ... nothing changed!"
  else
    rm $DIR/once.sh
    cp $ONCE_DIR/src/sh/once.sh $DIR
    ls -alF $DIR/once*
  fi
}

once.docker(){

    if [ "$1" = "WODA" ] || [ "$1" = "woda" ]; then
      if [ "$2" = "server" ] || [ "$2" = "Server" ]; then
        if [ "$3" = "build" ] || [ "$3" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/
          ./buildDockerFileServer
        elif [ "$3" = "run" ] || [ "$3" = "RUN" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/
          ./runDockerFileServer
        else
          echo "Invalid Docker Command..."
        fi
      elif [ "$2" = "local" ] || [ "$2" = "LOCAL" ]; then
        if [ "$3" = "build" ] || [ "$3" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/
          ./buildDockerFileLocal
        elif [ "$3" = "run" ] || [ "$3" = "RUN" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/
          ./runDockerFileLocal
        else
          echo "Invalid Docker Command..."
        fi
      else
        echo "Invalid Docker Command..."
      fi
    elif [ "$1" = "nodejs" ] || [ "$1" = "Nodejs" ];then
        if [ "$2" = "build" ] || [ "$2" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Nodejs/14/
          ./buildDocker
        elif [ "$2" = "run" ] || [ "$2" = "RUN" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Nodejs/14/
          ./runDocker
        else
          echo "Invalid Docker Command..."
        fi
    elif [ "$1" = "structr" ] || [ "$1" = "Structr" ];then
        if [ "$2" = "build" ] || [ "$2" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Openjdk/8/Structr/2.1.4/
          ./buildDocker
        elif [ "$2" = "run" ] || [ "$2" = "RUN" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Openjdk/8/Structr/2.1.4/
          ./runDocker
        else
          echo "Invalid Docker Command..."
        fi
    elif [ "$1" = "open-ssl" ] || [ "$1" = "Open-SSL" ];then
        if [ "$2" = "build" ] || [ "$2" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Nginx/1.15/certbot/1.7.0/test.wo-da.de/
          ./buildDocker
        elif [ "$2" = "run" ] || [ "$2" = "RUN" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/1.0.0/Alpine/3.13.2/Nginx/1.15/certbot/1.7.0/test.wo-da.de/
          ./runDocker
        else
          echo "Invalid Docker Command..."
        fi
    elif [ "$1" = "nakedalpine" ] || [ "$1" = "nakedAlpine" ] || [ "$1" = "minimulLinux" ] || [ "$1" = "minimullinux" ];then
        if [ "$2" = "build" ] || [ "$2" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedAlpine/3.13.2/
          ./buildDockerfile
        elif [ "$2" = "run" ] || [ "$2" = "RUN" ]; then
          if [ "$3" = "eamd" ] || [ "$3" = "EAMD" ]; then
            cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedAlpine/3.13.2/
            ./runDockerWithEAMD
          else
            cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedAlpine/3.13.2/
              ./runDockerfile
          fi
        else
          echo "Invalid Docker Command..."
        fi
    elif [ "$1" = "nakedubuntu" ] || [ "$1" = "nakedUbuntu" ];then
        if [ "$2" = "build" ] || [ "$2" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedUbuntu18.4/
          ./buildDockerfile
        elif [ "$2" = "run" ] || [ "$2" = "RUN" ]; then
          if [ "$3" = "eamd" ] || [ "$3" = "EAMD" ]; then
            cd cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedUbuntu18.4/
            ./runDockerWithEAMD
          else
            cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedUbuntu18.4/
            ./runDockerfile
          fi
        else
          echo "Invalid Docker Command..."
        fi
    elif [ "$1" = "nakeddebian" ] || [ "$1" = "nakedDebian" ];then
        if [ "$2" = "build" ] || [ "$2" = "BUILD" ]; then
          cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedDebian9.12/
          ./buildDockerfile
        elif [ "$2" = "run" ] || [ "$2" = "RUN" ]; then
            cd /var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/nakedDebian9.12/
            ./runDockerfile
        else
          echo "Invalid Docker Command..."
        fi
    else
      echo "No Such Docker Image Found...."
    fi
}

function once.better.docker()
{
    case $1 in
      WODA)
        shift
        once.docker.woda
        "$@"
        ;;
      nodejs)
        shift
        once.docker.nodejs
        "$@"
        ;;
      structr)
        once.docker.structr "$@"
        ;;
      '')
        debug.log "$0: EXIT"
        #exit 0
        return
        ;;
      *)
        console.log "once.stage to: $@"
        once.stage docker.$1 "$@"
    esac
}


function once.docker.install(){
  if [ -z "$USERNAME" ]; then
    export USERNAME="${USER}"
  fi
  if [ ! $USERNAME = "root" ]; then
    echo "Super User Permissin Required..! Re-run it with super user"
    exit 0;
  fi
  if [ -x "$(command -v brew)" ]; then
            brew cask install docker
            brew install docker-compose
        elif [ -x "$(command -v apk)" ]; then
            apk update
            apk add docker
            addgroup $USERNAME docker            
            rc-update add docker boot
            service docker start
            apk add docker-compose
        elif [ -x "$(command -v apt-get)" ]; then
            echo "Installing Docker & Docker Compose..."
            apt-get -y install curl apt-transport-https ca-certificates curl gnupg2 software-properties-common
            curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
            apt-get update
            apt-get -y install docker-ce docker-ce-cli containerd.io
            usermod -aG docker $USERNAME
            curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            docker --version
            docker-compose --version
        elif [ -x "$(command -v pacman)" ]; then
            echo "Installing Docker & Docker Compose..."
            pacman -Syu
            echo "installing Docker......"
            pacman -S --needed docker
            echo "installing Docker Compose......"
            pacman -S --needed docker-compose
            groupadd docker
            gpasswd -a ${USERNAME} docker
        else
            message "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $1";
        fi
}


function once.check.installation.mode() {
  #stop.log "once.check.installation.mode $COMMANDS"
  local mode=$COMMANDS
  if [ -z "$mode" ]; then 
        console.log "once.check.installation.mode with no parameters!"
        mode=DOCKER
  fi

  case $mode in
    docker.build)
      console.log "once installation mode: $COMMANDS"
      export ONCE_BUILD=BUILDING
      warn.log "once is in mode: during Dockerfile build"
      return 0
      ;;
    LOCAL)
      console.log "once installation mode: $COMMANDS"
      ;;
    DOCKER)
      console.log "once installation mode: $COMMANDS"
      ;;      
  esac
  


}


once.init()                 # forces reinitialisation
{
  #stop.log "entered once.init"
  export PS4='+${LINENO}: '
  clear
  unset NEW
  once.version
  once.check.installation.mode "$@"

  console.log "initialize Once"


  #wo-da.de IP for once.update
  ONCE_DEFAULT_SSH_IP=178.254.36.232
  
  #for once.load
  #ONCE_LOCAL_SERVER=http://192.168.178.49:8080
  
  ONCE_DEFAULT_SERVER=test.wo-da.de
  ONCE_SHELL=$SHELL
  #ONCE_USERHOME=$(cd;pwd)

  ONCE_REPO_NAME=EAMD.ucp
  ONCE_REPO_COMPONENTS=Components
  ONCE_REPO_SCENARIOS=Scenarios
  
  if [ -z "$ONCE_INITIAL_PATH" ]; then
    console.log "saving inital PATH"
    ONCE_INITIAL_PATH=$PATH
  fi

  ONCE_LATEST_BRANCH=test/sprint21
  ONCE_SCENARIO_BRANCH=test/WODA

  ONCE_REVERSE_PROXY_CONFIG='[["auth","test.wo-da.de"],["snet","test.wo-da.de"],["structr","test.wo-da.de"]]'
  ONCE_REV_PROXY_HOST=127.0.0.1
  ONCE_REV_PROXY_PORT=5002
  ONCE_PROXY_HOST=127.0.0.1
  ONCE_PROXY_PORT=5001

  if [ -z "ONCE_SCENARIO" ]; then
      stop.log "setting NEW ONCE_SCENARIO"
      ONCE_SCENARIO=$SCENARIOS_DIR/$(cat $ONCE_DEFAULT_SCENARIO/once.scenario)
  fi 



  #stepDebugger ON
  #once.check.privileges
  
  if [ -n "$1" ]; then
    ONCE_REPO_PREFIX=$1
    console.log "custom.installation: at $ONCE_REPO_PREFIX"
    ONCE_STATE=user.installation
  fi
 
  once.check.privileges



  #once.stage
}

function once.update.variables()     # updates the environmental variables: REPO_DIR, COMPONENTS_DIR, SCENARIOS_DIR, ONCE_DIR, ONCE_DEFAULT_SCENARIO, ONCE_LOAD_DIR
{
  #stop.log "update Variables:"

  export REPO_DIR=$ONCE_REPO_PREFIX/$ONCE_REPO_NAME
  export COMPONENTS_DIR=$REPO_DIR/$ONCE_REPO_COMPONENTS
  export SCENARIOS_DIR=$REPO_DIR/$ONCE_REPO_SCENARIOS
  ONCE_DIR=$COMPONENTS_DIR/tla/EAM/layer1/Thinglish/Once/latestServer
  
  if [ ! -d "$ONCE_DEFAULT_SCENARIO" ]; then 
    console.log "no default scenario, using localhost"
    ONCE_DEFAULT_SCENARIO=$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer
  fi
  
  ONCE_LOAD_DIR=$SCENARIOS_DIR/localhost/EAM/1_infrastructure/Once/latestServer/oosh

  if [ -z "$ONCE_STRUCTR_SERVER" ]; then 
    console.log "no default ONCE_STRUCTR_SERVER"
    ONCE_STRUCTR_SERVER=https://$ONCE_DEFAULT_SERVER:$ONCE_REV_PROXY_PORT
    console.log "  setting: $ONCE_STRUCTR_SERVER"
  fi

  if [ -z "$ONCE_DEFAULT_HOST" ] ; then
    ONCE_DEFAULT_HOST=$ONCE_DEFAULT_SERVER
    warn.log "ONCE_DEFAULT_SERVER is deprecated: pleas usee ONCE_DEFAULT_HOST or ONCE_DEFAULT_URL instead"
  fi

  if [ -z "$ONCE_DEFAULT_SERVER" ] ; then
    #ONCE_DEFAULT_SERVER=$ONCE_DEFAULT_HOST
    warn.log "ONCE_DEFAULT_SERVER is deprecated: please use ONCE_DEFAULT_HOST or ONCE_DEFAULT_URL instead"
  fi
  
  if [ -z "$ONCE_DEFAULT_URL" ] ; then
    ONCE_DEFAULT_URL=https://$ONCE_DEFAULT_HOST
  fi
  
  if [ -z "$ONCE_POSTGRES_CONNECTION_STRING" ] ; then
    ONCE_POSTGRES_CONNECTION_STRING=postgresql://root:qazwsx123@once-postgresql:5433/oncestore
  fi

  if [ -z "$ONCE_DIRECT_HTTPS_URL" ] ; then
    ONCE_DIRECT_HTTPS_URL=https://$ONCE_DEFAULT_HOST:8443
  fi


  if [ -z "$ONCE_DEFAULT_DOCKER_POSTGRESQL" ] ; then
    export ONCE_DEFAULT_DOCKER_POSTGRESQL=/var/dev/EAMD.ucp/3rdPartyComponents/org/postgresql/PostgreSQL/12.2/
  fi

  if [ -z "$ONCE_DEFAULT_DOCKER_WODA" ] ; then
    export ONCE_DEFAULT_DOCKER_WODA=/var/dev/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/DockerWorkspaces/WODA/2.0.0/Ubuntu/20.04/Nodejs/16
  fi
  
  if [ -z "$ONCE_DEFAULT_SCENARIO_DOCKER" ] ; then
    export ONCE_DEFAULT_SCENARIO_DOCKER="${ONCE_DEFAULT_SCENARIO:0:${#ONCE_DEFAULT_SCENARIO}-17}"
  fi

  if [ -z "$ONCE_DEFAULT_UDE_STORE" ] ; then
    ONCE_DEFAULT_UDE_STORE=https://localhost:8443
  fi

  if [ -z "$ONCE_DEFAULT_KEYCLOAK_SERVER" ] ; then
    export ONCE_DEFAULT_KEYCLOAK_SERVER='{ "realm": "master", "clientId": "shifternetzwerk", "url": "https://test.wo-da.de/auth"}'
  fi

  export ONCE_DIR
  checkAndFix  "default ONCE_LOAD_DIR location" "-d" "$ONCE_LOAD_DIR" "once.path.create $ONCE_LOAD_DIR"

  ONCE_PATHS=$ONCE_DEFAULT_SCENARIO/paths

  #stop.log "writing NEW $ONCE_DEFAULT_SCENARIO/.once"
  #set | grep "^\(export \)*ONCE_" | sed 's/^\(export \)*\(ONCE_\)\(.*\)=\(.*\)/export \2\3=\4/' >$ONCE_DEFAULT_SCENARIO/.once

  warn.log "updating $ONCE_DEFAULT_SCENARIO/.once"
  set | grep "^\(export \)*ONCE_EXPORT_" | sed 's/^\(export \)*\(ONCE_EXPORT_\)\(.*\)/export \3/' >./tmp.once.export.env
  cat ./tmp.once.export.env
  source ./tmp.once.export.env
  rm ./tmp.once.export.env
}


once.unset() 
{
  export TMP_SCENARIO=$ONCE_DEFAULT_SCENARIO
  set | grep "^\(export \)*ONCE_" | sed 's/^\(export \)*\(ONCE_\)\(.*\)=\(.*\)/unset \2\3/' >tmp.once.clear.env
  source tmp.once.clear.env
  rm tmp.once.clear.env
  export ONCE_DEFAULT_SCENARIO=$TMP_SCENARIO
  unset TMP_SCENARIO

  #grep "^\(export \)*ONCE_" $ONCE_DEFAULT_SCENARIO/.once | sed 's/^\(export \)*\(ONCE_\)\(.*\)=\(.*\)/\1\2\3=\4/' 
  stop.log "updating $ONCE_DEFAULT_SCENARIO/.once"
  grep "^\(export \)*ONCE_" $ONCE_DEFAULT_SCENARIO/.once | sed 's/^\(export \)*\(ONCE_\)\(.*\)=\(.*\)/export \2\3=\4/' 
  #exit
  grep "^\(export \)*ONCE_" $ONCE_DEFAULT_SCENARIO/.once | sed 's/^\(export \)*\(ONCE_\)\(.*\)=\(.*\)/export \2\3=\4/'  >$ONCE_DEFAULT_SCENARIO/.once.new
  
  #echo export ONCE_DEFAULT_SCENARIO=$ONCE_DEFAULT_SCENARIO >~/.once
  # echo . $ONCE_DEFAULT_SCENARIO/.once >>~/.once
  # echo PATH=$PATH >>~/.once

  stop.log "list current new: $ONCE_DEFAULT_SCENARIO/.once"
  cat $ONCE_DEFAULT_SCENARIO/.once.new

  stop.log "entering shell with the new config"
  once.sh

}

function once.stage()                # transitions to the next state of th ONCE STATE MACHINE and saves it for recovery
{
  debug.log "once.stage: -$1- COMMANDS=-$COMMANDS- RETURN=-$RETURN- @=-$@-"
  
  if [ -n "$1" ]; then
	  ONCE_STATE=$1
    once.hibernate update
  fi
  if [ "$ONCE_STATE" = "stage" ] ; then
	  ONCE_STATE=status
    once.stage
    return
  fi
  if [ -z "$ONCE_STATE" ] ; then
	  ONCE_STATE=discover
  fi
  #test -t 1 && tput bold; tput setf 6                                    ## white yellow
  echo -e "\033[1;96mOnce transition to: $ONCE_STATE\033[0m"
  #test -t 1 && tput sgr0 # Reset terminal
  shift
  debug.log "next arguments: $@"

  #if [ "ON" = "$DEBUG" ]; then 
  #  stepDebugger ON
  #fi

  once.$ONCE_STATE "$@"
  if [ "$?" = "0" ]; then
    return $?
  else
    err.log "$?"
    once.stage done
  fi
}


function once.hibernate()            # save environmental variables and puts once in hibernation 
{

  #writes all ONCE_ env variables to .once in the users home directroy
  #if [ -n "$ONCE_SCENARIO" ]; then
  #  ONCE_DEFAULT_SCENARIO=$ONCE_SCENARIO/EAM/1_infrastructure/Once/latestServer
  #fi

	#set | grep ^ONCE_ >$ONCE_DEFAULT_SCENARIO/.once
  #set | grep ^ONCE_ | sed 's/^\(ONCE_\)\(.*\)=\(.*\)/unset \1\2/' >$ONCE_DEFAULT_SCENARIO/.once
  

  set | grep "^\(export \)*ONCE_" | sed 's/^\(export \)*\(ONCE_\)\(.*\)=\(.*\)/export \2\3=\4/' >$ONCE_DEFAULT_SCENARIO/.once
  echo export ONCE_DEFAULT_SCENARIO=$ONCE_DEFAULT_SCENARIO >~/.once
  echo . $ONCE_DEFAULT_SCENARIO/.once >>~/.once
  echo PATH=$PATH >>~/.once
  
  if [ -z "$1" ]; then
    console.log "hibernating once.sh"
    exit 0
  fi
}

function once.sh() {
  stop.log "entering once shell level $(($SHLVL/2+1))"  #whitespace is totally important
  bash
  stop.log "back to once shell level $(($SHLVL/2))"
  if [ $SHLVL == 2 ]; then
      console.log "bottom reached .... do not exit the shell again"
  fi
}

function once.sh.exit()                           # exits until at shell level 1 
{
    if [ $SHLVL == 2 ]; then
      stop.log "back to once shell level $SHLVL"
      console.log "bottom reached .... not exiting shell"
      return      
    else
      stop.log "back to once shell level $SHLVL"
      exit
    fi
    source $ONCE_DEFAULT_SCENARIO/.once
}

once.mode()                 # sets the mode to either LOCAL or DOCKER and defines if "once start" tries to use local npm oder npm in a docker container
{
    if [ -z "$ONCE_MODE" ]; then 
      ONCE_MODE=LOCAL
    fi

    if [ -z "$1" ]; then 
        console.log "ONCE MODE: $ONCE_MODE"
        once.stage done
        return
    fi
    once.server.stop
    console.log "set ONCE MODE to: $1"
    ONCE_MODE=$1
    shift
    RETURN=$1
    once.stage done
}

once.restart()
{
  once.server.stop
  once.server.start fast
}

once.test()
{
  once.server.stop
  cd $ONCE_DIR
  npm install
  npm test
}

once.start()                # starts the Once Server in the background and remembers its PID; that is if no ohter instance of once is running (the forceful start of another once server is on a dynamic port counting upward from 8080)
{
  COMMANDS="$@"
  #stop.log "once.discover $COMMANDS"
  once.discover "$@"
  if [ -z "$1" ]; then 
        console.log "no parameters! stage to: $ONCE_STATE"
        once.stage
        console.log "$this: Bye"
        
        once.done
  fi

  while [ -n $1 ]; do
    debug.log "start 1: -$1-"
    case $1 in
      call)
        shift
        "$@"
        ;;
      discover)
        once.discover
        if [ "$ONCE_STATE" = "disvocer" ]; then
          ONCE_STATE=check.installation
          once.stage
        fi
        ;;
      start)
        once.server.start "$@"
        ;;
      X)
        echo "Set DEBUG to X"
        shift
        echo "RETRUN $1"
        RETURN=$1
        ;;
      '')
        debug.log "$0: EXIT"
        #exit 0
        return
        ;;
      *)
        console.log "once.stage to: $@"
        once.stage "$@"
    esac

    while [ ! "$RETURN" = "$1" ]; do
      shift
      debug.log "shift:  -Return:$RETURN-  -$1- -command=$COMMANDS-  =$@="
      if [ -z "$1" ]; then
        debug.log "force stop"
        RETURN=
        exit 0
      fi
    done
    debug.log "found RETURN=$1"
    RETURN=$2
    
  done
  debug.log "will stage"
  once.stage $ONCE_STATE
  
}

function once.startlog(){
  # once.sh
  once.links.fix
  once.server.stop
  once.server.start.inDocker
  once.log
  # tail -f /var/dev/EAMD.ucp/Scenarios/localhost/EAM/1_infrastructure/Once/latestServer/.once
}

function once.docker.network(){
  
  echo "Checking Docker Network Status..."
  NETWORK_NAME=once-woda-network
  if [ -z $(docker network ls --filter name=^${NETWORK_NAME}$ --format="{{ .Name }}") ] ; then 
      echo "once-woda-network not exissts, creating new..."
      docker network create ${NETWORK_NAME} ; 
      echo "once-woda-network docker network created."
      echo
  else
    echo "Docker Network 'once-woda-network' Already Exists..."
  fi
}

# once.clone.3rdpartycomponents(){

# }
function once.docker.folder.check(){
  cd $ONCE_DEFAULT_SCENARIO_DOCKER;
  if [ -d "./Docker" ]; then
    echo "Docker Directory in Scenario Default Location exists....";
  else
    echo "Creating 'Docker/' directory In Scenario Default Location.....";
    mkdir -p Docker
  fi
}

function once.docker.pgadmin.createdc(){
  once.docker.folder.check
  cd ${ONCE_DEFAULT_SCENARIO_DOCKER}/Docker/
  if [ -d "./pgAdmin" ]; then
    echo "pgAdmin Directory in Scenario Default Location exists....";
  else
    echo "Creating 'pgAdmin/' directory In Scenario Default Location.....";
    mkdir -p pgAdmin
    mkdir -p pgAdmin/4.18/    
  fi
  cd pgAdmin/4.18/
  if [ -f "pgAdmin.env" ]; then
    echo "pgAdmin.env file already exists...";
  else
  

    echo "Creating pgAdmin.env file"
    echo "PGADMIN_DEFAULT_EMAIL=admin@admin.com" >> pgAdmin.env
    echo "PGADMIN_DEFAULT_PASSWORD=qazwsx123" >> pgAdmin.env
    echo 
    echo "pgAdmin.env file created..."
    cat pgAdmin.env
    echo 

  fi
  if [ -f "docker-compose.yml" ]; then
    echo "docker-compose file already exists...";
  else
  
    echo 'version: "3.7"' >> docker-compose.yml
    echo 'services:' >> docker-compose.yml
    echo '  pgadmin:' >> docker-compose.yml
    echo '    container_name: once-pgadmin' >> docker-compose.yml
    echo '    image: dpage/pgadmin4:4.18' >> docker-compose.yml
    echo '    restart: always' >> docker-compose.yml
    # echo '    hostname: postgresql-db.docker.local' >> docker-compose.yml
    echo '    env_file:' >> docker-compose.yml
    echo '      - pgAdmin.env' >> docker-compose.yml
    echo '    volumes:' >> docker-compose.yml
        
    echo '      - pgadmin-data:/var/lib/pgadmin' >> docker-compose.yml
    echo '    ports:' >> docker-compose.yml
    echo '      - "8099:80"'  >> docker-compose.yml
    echo '      - "7443:443"'  >> docker-compose.yml
    # echo '    links:' >> docker-compose.yml
    # echo '      - "postgresql-db-12"'  >> docker-compose.yml
    echo  ''      >> docker-compose.yml
    echo  ''      >> docker-compose.yml
    echo 'volumes:' >> docker-compose.yml
    echo '  pgadmin-data:' >> docker-compose.yml
    # echo '  pgadmin-data:' >> docker-compose.yml
    echo 'networks:' >> docker-compose.yml
    echo '  default:' >> docker-compose.yml
    echo '    external:' >> docker-compose.yml
    echo '      name: once-woda-network' >> docker-compose.yml

  fi
  
  echo 
  echo ".env file created with details:"
  echo
  cat pgAdmin.env
  echo 
  echo "docker-compose file created with details:"
  echo
  cat docker-compose.yml
  tree
}

function once.docker.postgresql.createdc(){
  once.docker.folder.check
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/
  if [ -d "./PostgreSQL" ]; then
    echo "PostgreSQL Directory in Scenario Default Location exists....";
  else
    echo "Creating 'PostgreSQL/' directory In Scenario Default Location.....";
    mkdir -p PostgreSQL
    mkdir -p PostgreSQL/12.2/    
  fi
  cd PostgreSQL/12.2/
  if [ -f "postgresql.env" ]; then
    echo "postgresql.env file already exists...";
  else
    echo "Creating postgresql.env file"
    echo "POSTGRES_USER=root" >> postgresql.env
    echo "POSTGRES_PASSWORD=qazwsx123" >> postgresql.env
    echo "POSTGRES_DB=oncestore" >> postgresql.env
    echo "APP_DB_USER=once" >> postgresql.env
    echo "APP_DB_PASS=qazwsx123" >> postgresql.env
    echo "APP_DB_NAME=oncestore" >> postgresql.env
    echo 
    echo "postgresql.env file created..."
    cat postgresql.env
    echo 

  fi
  if [ -f "docker-compose.yml" ]; then
    echo "docker-compose file already exists...";
  else
    echo 'version: "3.7"' >> docker-compose.yml
    echo 'services:' >> docker-compose.yml
    echo '  postgresql-db-12:' >> docker-compose.yml
    echo '    container_name: once-postgresql' >> docker-compose.yml
    echo '    image: postgres:12.2' >> docker-compose.yml
    echo '    restart: always' >> docker-compose.yml
    # echo '    hostname: postgresql-db.docker.local' >> docker-compose.yml
    echo '    env_file:' >> docker-compose.yml
    echo '      - postgresql.env' >> docker-compose.yml
    echo '    volumes:' >> docker-compose.yml
    if [ ! -d "db.init" ]; then
      mkdir -p db.init
      cd db.init
      wget https://test.wo-da.de/EAMD.ucp/3rdPartyComponents/org/postgresql/PostgreSQL/12.2/db/01-init.sh
      cd ..
      echo '      - ./db.init:/docker-entrypoint-initdb.d/' >> docker-compose.yml
    else
      echo '      - ./db.init:/docker-entrypoint-initdb.d/' >> docker-compose.yml
      # echo '      - /var/dev/EAMD.ucp/3rdPartyComponents/org/postgresql/PostgreSQL/12.2/db:/docker-entrypoint-initdb.d/' >> docker-compose.yml
    fi
    
    echo '      - ./oncestore.db:/var/lib/postgresql/data' >> docker-compose.yml
    echo '    ports:' >> docker-compose.yml
    echo '      - "5433:5432"'  >> docker-compose.yml
    echo  ''      >> docker-compose.yml
    echo  ''      >> docker-compose.yml
    echo 'volumes:' >> docker-compose.yml
    echo '  db-data:' >> docker-compose.yml
    # echo '  pgadmin-data:' >> docker-compose.yml
    echo 'networks:' >> docker-compose.yml
    echo '  default:' >> docker-compose.yml
    echo '    external:' >> docker-compose.yml
    echo '      name: once-woda-network' >> docker-compose.yml

  fi
  # pwd
  # ls -AlF
  echo 
  echo "docker-compose file created with config details:"
  echo
  cat docker-compose.yml
  tree
  
}

once.docker.dc.setup() #to setup PostgreSQL, pgAdmin & WODA docker in default scenario
{
  echo "Creating Docker Network......"
  echo "==================================================================="
  once.docker.network
  echo "Creating Scenerio Default Docker Directory......"
  echo "==================================================================="
  once.docker.folder.check
  echo "Creating PostgreSQL docker config files......"
  echo "==================================================================="
  once.docker.postgresql.createdc
  echo "Building PostgreSQL docker config files......"
  echo "==================================================================="
  once.docker.postgresql.build
  echo "Creating pgAdmin docker config files......"
  echo "==================================================================="
  once.docker.pgadmin.createdc
  echo "Building pgAdmin docker config files......"
  echo "==================================================================="
  once.docker.pgadmin.build
  echo "Creating WODA docker config files......"
  echo "==================================================================="
  once.docker.woda.createdc
  echo "Building WODA docker......"
  echo "==================================================================="
  # once.docker.woda.build
  echo "Docker Build Completed....";
  echo "==================================================================="
}

function once.docker.pgadmin.build(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/pgAdmin/4.18/
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep once-pgadmin 
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    echo "Container is not runing...";
    echo "Building container...";
    docker-compose build
  fi
}

function once.docker.pgadmin.rebuild(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/pgAdmin/4.18/
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep once-pgadmin 
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    echo "Container is not runing...";
    echo "Building container...";
    docker-compose build --no-cache
  fi
}

function once.docker.pgadmin.start(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/pgAdmin/4.18/
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep once-pgadmin 
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    echo "Container is not runing...";
    echo "Building container...";
    docker-compose up
  fi
}



function once.docker.postgresql.build(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/PostgreSQL/12.2
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep once-postgresql 
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    echo "Container is not runing...";
    echo "Building container...";
    docker-compose build
  fi
}

function once.docker.postgresql.rebuild(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/PostgreSQL/12.2
  docker-compose ps --services --filter "status=running" | grep once-postgresql 
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    echo "Container is not runing...";
    echo "Building container...";
    docker-compose build --no-cache
  fi
}


function once.docker.postgresql.start(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/PostgreSQL/12.2
  docker-compose ps --services --filter "status=running" | grep once-postgresql 
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    echo "Container is not runing...";
    echo "Starting container...";
    docker-compose up --build
  fi
}





function once.get_current_env(){
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0
  if [ -f "current.env" ]; then
    rm current.env
  else
    echo ONCE_DOCKER_HOST=$HOSTNAME >> current.env
    export ONCE_DOCKER_HOST=$HOSTNAME
  fi
}

function once.copy_once_to_default_woda_docker(){
  if [ -f "$ONCE_DEFAULT_DOCKER_WODA/once.sh" ]; then
    rm $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0/once.sh
  fi
  cp $ONCE_DIR/src/sh/once.sh $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0
}

function once.docker.woda.createdc(){
  once.docker.folder.check
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/
  if [ -d "./WODA" ]; then
    echo "WODA Directory in Scenario Default Location exists....";
  else
    echo "Creating 'WODA/' directory In Scenario Default Location.....";
    mkdir -p WODA
    mkdir -p WODA/4.3.0    
  fi
  cd WODA/4.3.0
  if [ -f "current.env" ]; then
    rm current.env
  fi
  echo ONCE_DOCKER_HOST=$HOSTNAME >> current.env
  export ONCE_DOCKER_HOST=$HOSTNAME
  cat current.env
  tree
  if [ ! -f "once.sh" ]; then
      cp /var/dev/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh/once.sh ./
  fi
  if [ -f "docker-compose.yml" ]; then
    echo "docker-compose file already exists...";
  else
    echo "version: '3'" >> docker-compose.yml

    echo "services:" >> docker-compose.yml
    echo "  woda-with-nodejs:" >> docker-compose.yml
    echo "    container_name: woda" >> docker-compose.yml
    echo "    build: './'" >> docker-compose.yml
    echo "    image: woda-nodejs:16.x" >> docker-compose.yml
        
    echo "    env_file:" >> docker-compose.yml
    echo "      - current.env" >> docker-compose.yml
    echo "    ports:" >> docker-compose.yml
    echo "      - 8080:8080" >> docker-compose.yml
    echo "      - 8643:8443" >> docker-compose.yml
    echo "      - 6001:5001" >> docker-compose.yml
    echo "      - 6002:5002" >> docker-compose.yml
    echo "    volumes:" >> docker-compose.yml
    echo "      - /var/dev/EAMD.ucp/Components/tla/EAM/layer1/Thinglish/Once/latestServer/src/sh/:/usr/local/sbin/" >> docker-compose.yml
    echo "      - /var/dev/EAMD.ucp:/var/dev/EAMD.ucp" >> docker-compose.yml
    echo "    command: 'once startlog'" >> docker-compose.yml
    echo "networks:" >> docker-compose.yml
    echo "  default:" >> docker-compose.yml
    echo "    external:" >> docker-compose.yml
    echo "      name: once-woda-network" >> docker-compose.yml
    cat docker-compose.yml
    
  fi
  if [ -f "Dockerfile" ]; then
    echo "Dockerfile already exists........."
  else
    echo "Creating Dockerfile......."
    echo "# Pull base image." >> Dockerfile
    echo "FROM ubuntu:20.04" >> Dockerfile


    echo "WORKDIR /root/" >> Dockerfile
    echo "ADD ./once.sh ./once.sh" >> Dockerfile
    echo "RUN chmod +x ./once.sh" >> Dockerfile
    echo "RUN ./once.sh docker.build" >> Dockerfile
    echo "RUN ./once.sh links.fix" >> Dockerfile
    # RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -

    echo "CMD [ "/bin/bash" ]" >> Dockerfile
    echo "# Expose ports." >> Dockerfile
    echo "EXPOSE 8080" >> Dockerfile    
    cat Dockerfile
    tree
  fi
}

function once.docker.woda.build(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0
  docker-compose ps --services --filter "status=running" | grep woda
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else      
    once.copy_once_to_default_woda_docker
    # once.get_current_env
    docker-compose build
  fi
}


function once.docker.woda.rebuild(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0
  docker-compose ps --services --filter "status=running" | grep woda
  export status=$?
  if [ $status = 0 ]; then
    echo "Container is runing...";
  else
    once.copy_once_to_default_woda_docker
    # once.get_current_env
    docker-compose build --no-cache
  fi
  
}

function once.docker.woda.start(){
  once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep woda
  export status=$?
  if [ $status = 0 ]; then
      echo "Container Already Runing...";
      echo "Entering Docker ...."
      docker exec -it woda bash
  else
    once.copy_once_to_default_woda_docker
    # once.get_current_env
    # pwd
    docker-compose up
  fi
  
}



once.docker.postgresql()  #to setup postgresql docker in default scenerio
{
  once.docker.postgresql.createdc
  once.docker.postgresql.build
  once.docker.postgresql.start
}

function once.docker.postgresql.down(){
  # once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/PostgreSQL/12.2
  docker-compose ps --services --filter "status=running" | grep once-postgresql 
  export status=$?
  if [ $status = 1 ]; then
    echo "Container is runing...";
    docker-compose down
  else
    echo "Container is not runing...";
  fi
}

once.docker.pgadmin() #to setup pgAdmin docker in default scenerio
{
  once.docker.pgadmin.createdc
  once.docker.pgadmin.build
  once.docker.pgadmin.start
}

function once.docker.pgadmin.down(){
  # once.docker.network
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/pgAdmin/4.18/
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep once-pgadmin 
  export status=$?
  if [ $status = 0 ]; then
    echo "Stoping Docker Container is runing...";
    docker-compose down
  else
    echo "Container is not runing...";
  fi
}

once.docker.woda()  #to setup WODA docker in default scenerio
{
  once.docker.woda.createdc
  # once.docker.woda.build
  once.docker.woda.start
}

function once.docker.woda.down(){
  cd $ONCE_DEFAULT_SCENARIO_DOCKER/Docker/WODA/4.3.0
  echo "Checking docker status...."
  docker-compose ps --services --filter "status=running" | grep woda
  export status=$?
  if [ $status = 0 ]; then
      echo "Container Runing...";
      echo "Stopping woda docker container...."
      docker-compose down
  else
      echo "Docker Container is not running..."
  fi
  
}

function once.1() {
  console.log "hello ${FUNCNAME[0]} ..."
  
  echo "$1 should be \"a\"" 
  a=$1 
  shift
  b=$1
  echo "$1 should be \"b\""
  shift
  c=$1
  echo "$1 should be \"c\""
  shift

  RETURN=$1

}
function once.2() {
  debug.log "hello ${FUNCNAME[0]} ..."
  echo "$1 should be \"d\""
  shift
  echo "$1 should be \"e\""
  shift
  RETURN=$1
}
function once.3() {
  console.log "hello ${FUNCNAME[0]} ..."
  echo "$1 should be \"f\""
  shift
  echo "$1 should be \"g\""
  shift
  RETURN=$1
}
function once.4(){
  grep -w '$1' /root/scripts/once
  export st=$?
  if [ $st = 1 ] && [ $1 != 'cmd']; then
    once $1
    shift
  else
    once cmd $1
    shift
  fi
}

once.start "$@"
