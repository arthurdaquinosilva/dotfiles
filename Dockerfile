# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set shell to bash for better compatibility during build
SHELL ["/bin/bash", "-c"]

# Update and install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ca-certificates \
    sudo \
    zsh \
    locales \
    tzdata \
    lsb-release \
    software-properties-common \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user
ARG USERNAME=arthur
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install development tools and databases via apt
RUN apt-get update && apt-get install -y \
    ripgrep \
    silversearcher-ag \
    tree \
    fzf \
    zoxide \
    bat \
    tmux \
    make \
    vim \
    htop \
    btop \
    glances \
    python3-pip \
    python3-dev \
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    liblzma-dev \
    zlib1g-dev \
    tk-dev \
    mysql-server \
    postgresql \
    postgresql-contrib \
    && ln -s /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install gh -y \
    && rm -rf /var/lib/apt/lists/*

# Install Lazygit
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') \
    && curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    && tar xf lazygit.tar.gz lazygit \
    && install lazygit /usr/local/bin \
    && rm lazygit.tar.gz lazygit

# Install Lazydocker
RUN curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash \
    && mv /root/.local/bin/lazydocker /usr/local/bin/lazydocker || mv $HOME/.local/bin/lazydocker /usr/local/bin/lazydocker || true

# Install Translate-shell
RUN curl -Lo trans git.io/trans \
    && chmod +x trans \
    && mv trans /usr/local/bin/

# Install Go
RUN GO_VERSION="1.22.2" \
    && curl -Lo go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Set up user environment
USER $USERNAME
WORKDIR /home/$USERNAME
ENV HOME=/home/$USERNAME

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install NVM and Node.js
ENV NVM_DIR=$HOME/.nvm
RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && npm install -g yarn git-split-diffs @anthropic-ai/claude-code

# Install Pyenv and Python
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH
RUN curl https://pyenv.run | bash \
    && eval "$(pyenv init -)" \
    && pyenv install 3.12.7 \
    && pyenv global 3.12.7

# Configure FZF shell integrations
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all

# Create dotfiles directory and copy content
RUN mkdir -p $HOME/dotfiles
COPY --chown=$USERNAME:$USERNAME . $HOME/dotfiles/

# Copy entrypoint script
COPY --chown=$USERNAME:$USERNAME entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Setup symlinks
RUN ln -sf $HOME/dotfiles/shell/macos/.zshrc $HOME/.zshrc \
    && ln -sf $HOME/dotfiles/terminal/tmux/.tmux.conf $HOME/.tmux.conf \
    && ln -sf $HOME/dotfiles/terminal/git/.gitconfig $HOME/.gitconfig \
    && mkdir -p $HOME/.config/lazygit && ln -sf $HOME/dotfiles/terminal/lazygit/config.yml $HOME/.config/lazygit/config.yml \
    && mkdir -p $HOME/.config/lazydocker && ln -sf $HOME/dotfiles/terminal/lazydocker/config.yml $HOME/.config/lazydocker/config.yml

# Setup Vim
RUN git clone https://github.com/arthurdaquinosilva/vim.git $HOME/.vim \
    && ln -sf $HOME/.vim/.vimrc $HOME/.vimrc \
    && curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    && vim +PlugInstall +qall || true

# Setup Tmux plugins
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
    && ~/.tmux/plugins/tpm/bin/install_plugins || true

# Set ZSH as default shell for the user
RUN sudo chsh -s /bin/zsh $USERNAME

# Final adjustments to .zshrc and .gitconfig to remove macOS specific parts or fix paths
RUN sed -i 's|/Users/arthurdaquino|/home/arthur|g' $HOME/.zshrc \
    && sed -i 's|/Users/arthurdaquino|/home/arthur|g' $HOME/.gitconfig

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/zsh"]
