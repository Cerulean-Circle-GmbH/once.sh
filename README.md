# once.sh
Unified shell environment for UCP components and ONCE the Object Network Communication Environment


## manual install
```
wget https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh ;
chmod 700 oosh
./oosh


or
cat oosh | sh -x
```
## use it anywhere

| Method    | Command                                                                                           |
|:----------|:--------------------------------------------------------------------------------------------------|
| **curl**  | `sh -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"` |
| **wget**  | `sh -c "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"`   |
| **fetch** | `sh -c "$(fetch -o - https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/main/init/oosh)"` |


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


## Advanced usage

setup a once server management environment

```
    oosh/init/once
    
```