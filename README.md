# once.sh
Unified shell environment for UCP components and ONCE the Object Network Communication Environment


This Repo consists of two main topics
1. The oosh object oriented bash environment with completion, logging and debugging
1. the once bash script to manage a ONCE installation into any environment
1. 1. Supported environments — see [Supported Platforms](docs/supported-platforms.md) for the full matrix

Code flows through a gated pipeline: `dev` → `stage` → `prod`. See [Branching Strategy](docs/branching.md) for details.

## prereqs

- **bash 4+** — macOS: `brew install bash` · Debian/Ubuntu/RHEL: already present
- **git** — macOS: `xcode-select --install` · Debian/Ubuntu: `sudo apt install git` · RHEL/Fedora: `sudo dnf install git`

The installer checks both and exits with a one-line hint if either is missing.

## one-file install

**One file, double-click (macOS) or `./` (Linux):**

1. **[⬇ Download Install oosh.command](https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/Install%20oosh.command)** (right-click → Save Link As…)
2. Run it:
   - **macOS:** double-click in Finder.
   - **Linux:** `chmod +x "Install oosh.command" && ./"Install oosh.command"`
3. A terminal runs the install. Enter your sudo password when prompted.

That's it — the `.command` file self-bootstraps: it fetches the bootstrap script from GitHub and runs it. No need to download the whole repo.

> **First-run macOS prompt:** downloaded files carry Apple's quarantine flag. macOS will say "*Install oosh.command* cannot be opened because the developer cannot be verified." Right-click the file → **Open** → **Open** to confirm. After you approve it once, double-click works normally. Linux has no equivalent gate.

> **Also works from a clone:** if you `git clone` the repo or download the ZIP, the same `Install oosh.command` in the repo root runs your local `init/oosh` instead of fetching from GitHub. Same UX either way.

> **Current default branch: `dev`.** Until we promote the install flow to `prod`, the download link and the `.command`'s embedded fallback URL both point to `dev`. After promotion, both get rewritten to `prod` (by `promote`) and this link will be updated.

## fast install - use it anywhere

| Method    | Command                                                                                           |
|:----------|:--------------------------------------------------------------------------------------------------|
| **curl**  | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)"` |
| **wget**  | `bash -c "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)"`   |
| **fetch** | `bash -c "$(fetch -o - https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)"` |

> **Current default branch: `dev`.** The new thin-bootstrap install flow only lives on `dev` until it's promoted through `testing` to `prod`. Once promoted, these URLs get flipped back to `/prod/`.

> **Note:** use `bash -c`, not `sh -c`. On Debian/Ubuntu `sh` is `dash`, and
> the `sh -c "$(curl …)"` form hits a pre-existing bug in oosh's re-exec-via-bash
> step: inside a piped script `$0` is literally `"sh"` (not a filesystem path),
> so `exec bash "$0" "$@"` becomes `exec bash sh` which bash resolves via PATH
> to `/usr/bin/sh` and fails with "cannot execute binary file". `bash -c` starts
> under bash directly so the re-exec is never attempted.

Substitute the `prod` segment of the URL with `dev` (or any branch name) to
install from a non-default branch, e.g. `…/dev/init/oosh`.


### More detailed logging for debugging is available with these commands
```
unbuffer env -i sh -xc "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)" | tee install.log.txt

> or if already available locally
unbuffer env -i sh -x init/oosh | tee install.log.txt 

> to view the file use 

less -r install.log.txt

> install unbuffer in one of the following ways
brew install expect
oo cmd expect
sudo apt-get install expect

```
in VSCODE use [use the ANSI Colors plugin](https://marketplace.visualstudio.com/items?itemName=iliazeus.vscode-ansi)

## manual install
```
wget https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh ;
chmod 700 oosh
./oosh


or
cat oosh | sh -x
```

### you do not have curl or wget: try

```
sudo apt update
sudo apt install curl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)"

or as root

apt update
apt install curl
bash -c "$(wget -O- https://raw.githubusercontent.com/Cerulean-Circle-GmbH/once.sh/dev/init/oosh)"
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
