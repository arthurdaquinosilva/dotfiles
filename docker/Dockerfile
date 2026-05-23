FROM ubuntu:22.04

# ============================================================================
# Build arguments — override with --build-arg at build time
# ============================================================================
ARG GO_VERSION=1.22.2
ARG NVM_VERSION=0.39.7
ARG PYTHON_VERSION=3.12.7
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color

# ============================================================================
# System packages (root)
# ============================================================================
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        build-essential curl wget git ca-certificates gnupg \
        lsb-release software-properties-common unzip zip make \
        htop btop glances locales \
        ripgrep silversearcher-ag tree fzf zoxide bat \
        tmux vim zsh \
        libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libffi-dev liblzma-dev zlib1g-dev tk-dev \
        python3-pip python3-dev \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# GitHub CLI
# ============================================================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# Lazygit
# ============================================================================
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    && tar xf /tmp/lazygit.tar.gz -C /tmp lazygit \
    && install /tmp/lazygit /usr/local/bin/lazygit \
    && rm -f /tmp/lazygit.tar.gz /tmp/lazygit

# ============================================================================
# Lazydocker
# ============================================================================
RUN curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh \
        | DESTINATION=/usr/local/bin bash

# ============================================================================
# Translate Shell
# ============================================================================
RUN curl -Lo /usr/local/bin/trans \
        "https://raw.githubusercontent.com/soimort/translate-shell/develop/trans" \
    && chmod +x /usr/local/bin/trans

# ============================================================================
# Go
# ============================================================================
RUN curl -Lo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm -f /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:$PATH"

# ============================================================================
# Non-root user
# ============================================================================
RUN groupadd -g ${GID} ${USERNAME} \
    && useradd -m -u ${UID} -g ${GID} -s /usr/bin/zsh ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ============================================================================
# Dotfiles
# ============================================================================
COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/dotfiles

# ============================================================================
# Oh My Zsh + retrowave theme + zsh-autosuggestions
# ============================================================================
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && cp ~/dotfiles/shell/macos/oh-my-zsh-themes.backup/retrowave.zsh-theme \
        ~/.oh-my-zsh/custom/themes/retrowave.zsh-theme \
    && git clone https://github.com/zsh-users/zsh-autosuggestions \
        ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# ============================================================================
# NVM + Node LTS + global packages
# ============================================================================
ENV NVM_DIR=/home/${USERNAME}/.nvm

RUN curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default lts/* \
    && npm install -g yarn git-split-diffs

# ============================================================================
# pyenv + Python
# ============================================================================
ENV PYENV_ROOT=/home/${USERNAME}/.pyenv
ENV PATH="${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:$PATH"

RUN curl https://pyenv.run | bash \
    && eval "$(pyenv init -)" \
    && pyenv install ${PYTHON_VERSION} \
    && pyenv global ${PYTHON_VERSION}

# ============================================================================
# Claude Code
# ============================================================================
ENV PATH="/home/${USERNAME}/.local/bin:$PATH"

RUN curl -fsSL https://claude.ai/install.sh | bash

# ============================================================================
# FZF shell integration
# ============================================================================
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all --no-bash --no-fish

# ============================================================================
# Vim config + plugins
# ============================================================================
RUN git clone https://github.com/arthurdaquinosilva/vim.git ~/.vim \
    && curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    && . "$NVM_DIR/nvm.sh" \
    && vim -c 'PlugInstall --sync' -c 'qa' 2>/dev/null || true

# ============================================================================
# Tmux plugins
# ============================================================================
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
    && ~/.tmux/plugins/tpm/bin/install_plugins || true

# ============================================================================
# Symlinks (mirrors what setup_symlinks does in common.sh)
# ============================================================================
RUN mkdir -p ~/.config/lazygit ~/.config/lazydocker \
    && ln -sf ~/dotfiles/shell/ubuntu/.zshrc ~/.zshrc \
    && ln -sf ~/dotfiles/terminal/tmux/.tmux.conf ~/.tmux.conf \
    && ln -sf ~/dotfiles/terminal/git/.gitconfig ~/.gitconfig \
    && ln -sf ~/dotfiles/terminal/lazygit/config.yml ~/.config/lazygit/config.yml \
    && ln -sf ~/dotfiles/terminal/lazydocker/config.yml ~/.config/lazydocker/config.yml \
    && ln -sf ~/.vim/.vimrc ~/.vimrc 2>/dev/null || true

# ============================================================================
# Go workspace PATH
# ============================================================================
ENV GOPATH=/home/${USERNAME}/go
ENV PATH="${GOPATH}/bin:$PATH"

# ============================================================================
# Entrypoint
# ============================================================================
CMD ["/usr/bin/zsh"]
