# Keep in sync with scripts/setup_ubuntu.sh (the same tools, in the same order).
FROM ubuntu:26.04

# ============================================================================
# Build arguments — override with --build-arg at build time
# ============================================================================
# Empty GO_VERSION = latest stable, like scripts/lib/common.sh
ARG GO_VERSION=
ARG NVM_VERSION=0.39.7
ARG PYTHON_VERSION=3.12.7
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color \
    SHELL=/usr/bin/zsh

# ============================================================================
# System packages (root)
# ============================================================================
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        build-essential curl wget git ca-certificates gnupg \
        lsb-release software-properties-common unzip zip make \
        htop btop glances locales \
        ripgrep silversearcher-ag tree fzf zoxide bat \
        vim-gtk3 xclip zsh ruby translate-shell \
        libssl-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libffi-dev liblzma-dev zlib1g-dev tk-dev libncurses-dev xz-utils \
        libevent-dev libutf8proc-dev pkg-config bison \
        python3-pip python3-dev \
        mysql-client postgresql-client \
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
RUN LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": *"v\K[^"]*') \
    && case "$(dpkg --print-architecture)" in arm64) ARCH=arm64 ;; *) ARCH=x86_64 ;; esac \
    && curl -fsSLo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" \
    && tar xf /tmp/lazygit.tar.gz -C /tmp lazygit \
    && install /tmp/lazygit /usr/local/bin/lazygit \
    && rm -f /tmp/lazygit.tar.gz /tmp/lazygit

# ============================================================================
# Lazydocker
# ============================================================================
RUN curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh \
        | DIR=/usr/local/bin bash

# ============================================================================
# Tmux (latest release, built from source like install_tmux)
# ============================================================================
RUN TMUX_VERSION=$(curl -fsSL "https://api.github.com/repos/tmux/tmux/releases/latest" \
        | grep -Po '"tag_name": *"\K[^"]*') \
    && mkdir -p /tmp/tmux \
    && curl -fsSL "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz" \
        | tar xz -C /tmp/tmux --strip-components=1 \
    && cd /tmp/tmux \
    && ./configure --enable-utf8proc \
    && make -j"$(nproc)" \
    && make install \
    && cd / \
    && rm -rf /tmp/tmux

# ============================================================================
# Go
# ============================================================================
RUN VERSION="${GO_VERSION:-$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1 | sed 's/^go//')}" \
    && curl -fsSLo /tmp/go.tar.gz "https://go.dev/dl/go${VERSION}.linux-$(dpkg --print-architecture).tar.gz" \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm -f /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:$PATH"

# ============================================================================
# Non-root user
# ============================================================================
# The base image ships an "ubuntu" user that already holds UID/GID 1000
RUN if getent passwd ubuntu >/dev/null; then userdel -r ubuntu; fi \
    && groupadd -g ${GID} ${USERNAME} \
    && useradd -m -u ${UID} -g ${GID} -s /usr/bin/zsh ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ============================================================================
# Dotfiles
# ============================================================================
COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/dotfiles

# ============================================================================
# Oh My Zsh + pitch theme + zsh-autosuggestions
# ============================================================================
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && mkdir -p ~/.oh-my-zsh/custom/themes \
    && ln -sf ~/dotfiles/shell/macos/oh-my-zsh-themes.backup/pitch.zsh-theme \
        ~/.oh-my-zsh/custom/themes/pitch.zsh-theme \
    && git clone https://github.com/zsh-users/zsh-autosuggestions \
        ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# ============================================================================
# Vim config
# ============================================================================
RUN git clone https://github.com/arthurdaquinosilva/vim.git ~/.vim

# ============================================================================
# Symlinks (mirrors what setup_symlinks does in common.sh)
# ============================================================================
# Runs after Oh My Zsh, whose installer replaces ~/.zshrc, and before the plugin
# installs below, which read ~/.tmux.conf and ~/.vimrc.
RUN mkdir -p ~/.config/lazygit ~/.config/lazydocker \
    && ln -sf ~/dotfiles/shell/ubuntu/.zshrc ~/.zshrc \
    && ln -sfn ~/dotfiles/bin ~/bin \
    && ln -sf ~/dotfiles/terminal/tmux/.tmux.conf ~/.tmux.conf \
    && ln -sf ~/dotfiles/terminal/git/.gitconfig ~/.gitconfig \
    && ln -sf ~/dotfiles/terminal/lazygit/config.yml ~/.config/lazygit/config.yml \
    && ln -sf ~/dotfiles/terminal/lazydocker/config.yml ~/.config/lazydocker/config.yml \
    && ln -sfn ~/dotfiles/terminal/bat ~/.config/bat \
    && ln -sfn ~/dotfiles/terminal/tmuxinator ~/.config/tmuxinator \
    && ln -sf ~/.vim/.vimrc ~/.vimrc \
    && bat cache --build \
    && printf '[split-diffs]\n\ttheme-directory = %s/dotfiles/terminal/git-split-diffs\n' "$HOME" > ~/.gitconfig.local

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
# Tmuxinator
# ============================================================================
RUN mkdir -p ~/.local/bin \
    && gem install --user-install --no-document --bindir ~/.local/bin tmuxinator

# ============================================================================
# FZF shell integration
# ============================================================================
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all --no-bash --no-fish --no-update-rc

# ============================================================================
# Tmux plugins
# ============================================================================
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
    && { ~/.tmux/plugins/tpm/bin/install_plugins || true; }

# ============================================================================
# Vim plugins
# ============================================================================
# vim-plug needs a terminal: without one it installs nothing. The second pass
# retries clones that fail when many run in parallel.
RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    && . "$NVM_DIR/nvm.sh" \
    && { script -qfec "vim -c 'PlugInstall --sync' -c 'PlugInstall --sync' -c 'qa'" /dev/null </dev/null >/dev/null || true; } \
    && if [ -d ~/.vim/plugged/vim-hexokinase ]; then make -C ~/.vim/plugged/vim-hexokinase hexokinase; fi

# ============================================================================
# Go workspace PATH
# ============================================================================
ENV GOPATH=/home/${USERNAME}/go
ENV PATH="${GOPATH}/bin:$PATH"

# ============================================================================
# Entrypoint
# ============================================================================
CMD ["/usr/bin/zsh"]
