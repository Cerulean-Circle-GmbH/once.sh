# once.sh
Unified shell environment for UCP components and ONCE the Object Network Communication Environment


This Repo consists of two main topics
1. The oosh object oriented bash envitonment with completion, logging and debugging
1. the once bash script to manage a ONCE installation into any environment
1. 1. Supportetd envionments currently are
    * Mac OS
    * Ubuntu
    * android termux App
    * iOS iSH App
    * RaspberryPI OS

## fast install - use it anywhere

| Method    | Command                                                                                           |
|:----------|:--------------------------------------------------------------------------------------------------|
| **curl**  | `sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"` |
| **wget**  | `sh -c "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"`   |
| **fetch** | `sh -c "$(fetch -o - https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"` |

## manual install
```
wget https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh ;
chmod 700 oosh
./oosh


or
cat oosh | sh -x
```

### you do not have curl or wget: try

```
sudo apt update
sudo apt install curl
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)

or as root

apt update
apt install curl
sh -c "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"
```


## Advanced usage: ONCE Server

setup a once server management environment

```
    oosh/init/once
    
```

The once server Installation is currently highly interactive and only supported as a **root** user.
Basically you will follow a state machine
```
    once v                                  # gives you the current once version
    once init                               # create a ONCE configuration for the current user

    **follow the state machine....*** once told you in `once init` what to do next
    once domain.set <your.domain.com>       # sets the domain for this installation. 
                                            # user localhost if its a development installation
    once domain.discover                    # gets the domain from the host configuration

    once states.list  <?all>                # shows you which state is currently set
                                            # the optional parameter all shows all states

    once stage next                         # tries to stage one step in the state list

    once check.STATE_NAME                   # checks if this state is already reached
    e.g.                                    # TAB completion should work. press TAB TAB to see all options
    once check.domain.set

    TROUBLE SHOOTING
    once state.su.set <stateNameOrNumber>   # sets the state hard so that you can skip states 

    once bind test.wo-da.de                 # binds the config to keycloak on test.wo-da.de
    
```
