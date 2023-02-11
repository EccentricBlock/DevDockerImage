# The Eccentric Build
Anti-Docker Pattern, Creating a Reproducible Dev/Audit Environment That Runs on a Raspberry PI.. I can feel rel0aded (a good friend) cringe from here.

The goal is to produce a deterministic developer image that can be used plugged into a dockerised environment to accelerate dev/audit type activities.


## How To Use
### Primary Access - SSH
The primary means of access to this image will be via SSH, the following authentication mechanisms are available.

* Username/Password
* authorized_keys

To take advantage of `authorized_keys` you need to set the `PUBLIC_KEY` environment variable with your `id_rsa.pub` (or equivalent).

**Note:** SSH pub keys have spaces, this can cause you a headache so the following are meant to help.  Notice there is a `\` to escape the spaces!

Docker-Compose
```
PUBLIC_KEY: ssh-ed25519\ AAA....TE5AAA...3Aaf....HslvFcn8W0Mn...P..Vbkr9X9\ EccentricBlock
```

CLI
```
-e PUBLIC_KEY=ssh-ed25519\ AAA....TE5AAA...3Aaf....HslvFcn8W0Mn...P..Vbkr9X9\ EccentricBlock
```

### User Account
The image loads you into a standard user account with sudo privs, to change the user and password.  Set the following ENV variables:
* USER_USERNAME
* USER_PASSWORD


## Remote Dev - VS Code
When developing, it is possible to use VS Code on your host system and have it remotely connect to the docker image.  This allows a consistent, clean environment.

It is possible to access the remote image via SSH using the `Remote Explorer`, link below:

https://code.visualstudio.com/docs/remote/ssh-tutorial#_connect-using-ssh

I have already installed the vs code server and a number of addons to save time with the install procedure, also handy if your on-site with no internet.

**Note:** If you dont have vs code installed locally, take a look at the example below where you can use the already installed vscode server to spin up a WebUI (hint, put traefik or similar infront).

https://medium.com/geekculture/3-steps-to-code-from-anywhere-45401247f479

## Build Setup

***Installed Development Environments***
* .NET Core SDK
* NodeJS v18
* Python 3
* Solidity
  * HardHat
  * solc & solc-select
* Visual Studio Code Server
  * a number of plugins.. update me