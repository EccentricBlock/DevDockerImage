
FROM ubuntu:jammy as base

#docker run --rm -it --entrypoint bash noodleware/devbox
#docker build --no-cache -t noodleware/devbox .


# Account will be created, this this for SSH access
ENV PUBLIC_KEY=""
ENV USER_USERNAME="user"
ENV USER_PASSWORD="Password1"
ENV LOCAL_DEV_FOLDER="/work"

# Install Core Tools
RUN apt update && \
    apt -y upgrade && \
    apt install -y apt-utils \
        build-essential \
        gcc \
        g++ \
        make \
        software-properties-common \
        apt-transport-https

#Install "Would be nice" Tools
RUN apt install -y \
        libatomic1 \
        net-tools \
        nano \
        python3-pip \         
        openssh-server \
        curl \
        git \
        jq \
        sudo

# Cleanup
RUN apt clean && \
    rm -rf \
        /var/tmp/* \
        /tmp/* 



# If We start a new stage, then all of above is cached
################################################################################
##  STAGE 2 BUILD - Tools
################################################################################

FROM base AS tool-install



######
# Install VS Code Server
######
#https://www.how2shout.com/linux/install-code-server-for-vs-code-on-ubuntu-22-04-or-20-04-lts/

RUN curl -fsSL https://code-server.dev/install.sh | sh

#systemctl enable --now code-server@${USER_USERNAME}

#Pre-Install extensions, less manual setup
RUN code-server --install-extension nomicfoundation.hardhat-solidity && \
    code-server --install-extension RemixProject.ethereum-remix && \
    code-server --install-extension tintinweb.solidity-visual-auditor && \
    code-server --install-extension tintinweb.vscode-vyper && \
    code-server --install-extension xgwang.mythril  && \
    code-server --install-extension trailofbits.slither-vscode && \
    code-server --install-extension tintinweb.ethereum-security-bundle && \
    code-server --install-extension tintinweb.vscode-solidity-flattener && \
    code-server --install-extension tintinweb.solidity-visual-auditor && \
    code-server --install-extension tintinweb.graphviz-interactive-preview && \
    code-server --install-extension ms-vscode.remote-explorer && \
    code-server --install-extension ms-vscode-remote.remote-ssh && \
    code-server --install-extension ms-vscode-remote.remote-ssh-edit && \
    code-server --install-extension yzhang.markdown-all-in-one && \
    code-server --install-extension ms-azuretools.vscode-docker && \
    code-server --install-extension formulahendry.docker-explorer && \
    code-server --install-extension redhat.vscode-yaml && \
    code-server --install-extension ms-python.python && \
    code-server --install-extension VisualStudioExptTeam.vscodeintellicode && \
    code-server --install-extension VisualStudioExptTeam.intellicode-api-usage-examples && \
    code-server --install-extension kevin-chatham.aspnetcorerazor-html-css-class-completion && \
    code-server --install-extension revrenlove.c-sharp-utilities && \
    code-server --install-extension adrianwilczynski.namespace && \
    code-server --install-extension kreativ-software.csharpextensions && \
    code-server --install-extension ms-dotnettools.csharp





### TODO ###: Code Server Is Not Running YET!!
# Plan is to move it to entry point with above extensions

# execute with the following args
 #--auth none
 #--disable-telemetry
 #--accept-server-license-terms
 #--host 0.0.0.0

 
# Install .NET Core
RUN curl -sL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    apt update && \ 
    apt install -y dotnet-sdk 


#Install NodeJS v18 & NVM
RUN curl -sL https://deb.nodesource.com/setup_18.x -o /tmp/nodesource_setup.sh && \
    bash /tmp/nodesource_setup.sh && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash && \
    apt update && \
    apt install nodejs && \
    npm install -g hardhat && \
    npm install -g @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers && \
    npm install -g @nomicfoundation/hardhat-toolbox hardhat-toolbox @openzeppelin/hardhat-upgrade hardhat-upgrade 


# Install SOLC and SOLC-SELECT
RUN add-apt-repository ppa:ethereum/ethereum && \
    apt update && \
    apt install solc && \
    pip3 install solc-select


# If We start a new stage, then all of above is cached
################################################################################
##  STAGE 3 BUILD - Configuration & Final Release
################################################################################

FROM tool-install AS final-release


######
# Setup SSH & Sudo, Create $USER_USERNAME and give SSH/Sudo access. 
######

#https://www.techrepublic.com/article/deploy-docker-container-ssh-access/

RUN mkdir /var/run/sshd && \
    #Enable SSH Password Auth
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    #Permit our normal user SSH logon rights
    echo "AllowUsers ${USER_USERNAME}" >> /etc/ssh/ssd_config && \
    #Add $USER_USERNAME 
    adduser --disabled-password --gecos '' ${USER_USERNAME} && \
    #Add $USER_USERNAME to sudo group
    adduser ${USER_USERNAME} sudo && \
    #Set USER_USERNAME password
    echo "${USER_USERNAME}:${USER_PASSWORD}" | chpasswd && \
    #Make sure sudo rule is present, DISABLE PASSWORD PROMPT
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    #Create the '/dev' folder to place code/work in
    mkdir ${LOCAL_DEV_FOLDER} && \
    #Make USER_USERNAME owner so we have RWX perms
    chown ${USER_USERNAME}:${USER_USERNAME} ${LOCAL_DEV_FOLDER} && \
    mkdir /home/${USER_USERNAME}/.ssh  && \
    chmod -R 700 /home/${USER_USERNAME}/.ssh && \
    touch /home/${USER_USERNAME}/.ssh/authorized_keys  && \
    chown -R ${USER_USERNAME}:${USER_USERNAME} /home/${USER_USERNAME}/.ssh && \
    chmod -R 600 /home/${USER_USERNAME}/.ssh/authorized_keys


EXPOSE 22
EXPOSE 80


COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

### TODO ###: Replace below with entrypoint.sh, tidy up FS modifications and settings inside here.
# CMD ["/usr/sbin/sshd", "-D"]



# VS Code Config / Entrypoint
# https://github.com/ruanbekker/docker-vscode-server/blob/main/bin/entrypoint.sh
