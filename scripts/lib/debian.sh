#!/usr/bin/env bash
# ============================================================================
# SHARED DEBIAN-FAMILY LIBRARY (Ubuntu, Kali, Debian)
# ============================================================================
# Sourced by setup_ubuntu.sh and setup_kali.sh after common.sh.
# ============================================================================

# ============================================================================
# APT
# ============================================================================
APT_OPTS=(-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)

apt_install() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get install "${APT_OPTS[@]}" "$@"
}

# Usage: apt_upgrade [upgrade|full-upgrade]
apt_upgrade() {
    local mode="${1:-upgrade}"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get "$mode" "${APT_OPTS[@]}"
}

# True if apt has an installable candidate for the package
apt_has_package() {
    local candidate
    candidate=$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')
    [[ -n "$candidate" && "$candidate" != "(none)" ]]
}

# ============================================================================
# HELPERS
# ============================================================================
# Prints the Debian-style arch: amd64 | arm64
linux_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac
}

# bat is installed as batcat on Debian/Ubuntu
link_batcat() {
    if command_exists batcat && ! command_exists bat; then
        sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
        log_success "Created bat symlink for batcat"
    fi
}

set_default_shell_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
        sudo chsh -s "$zsh_path" "$USER"
        log_success "Default shell set to zsh (takes effect on next login)"
    else
        log_info "zsh is already the default shell"
    fi
}

# ============================================================================
# TOOLS
# ============================================================================
install_github_cli() {
    log_info "Installing GitHub CLI..."
    command_exists gh && { log_info "GitHub CLI already installed"; return 0; }

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update && apt_install gh
    log_success "GitHub CLI installed"
}

install_lazygit() {
    log_info "Installing Lazygit..."
    command_exists lazygit && { log_info "Lazygit already installed"; return 0; }

    local version arch tmp
    case "$(linux_arch)" in
        amd64) arch="x86_64" ;;
        arm64) arch="arm64" ;;
    esac
    version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": *"v\K[^"]*')
    tmp=$(mktemp -d)
    curl -fsSLo "$tmp/lazygit.tar.gz" \
        "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz"
    tar xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
    sudo install "$tmp/lazygit" /usr/local/bin
    rm -rf "$tmp"
    log_success "Lazygit $version installed"
}

install_lazydocker() {
    log_info "Installing Lazydocker..."
    command_exists lazydocker && { log_info "Lazydocker already installed"; return 0; }

    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    [[ -f "$HOME/.local/bin/lazydocker" ]] && sudo mv "$HOME/.local/bin/lazydocker" /usr/local/bin/
    log_success "Lazydocker installed"
}

install_translate_shell() {
    log_info "Installing Translate Shell..."
    command_exists trans && { log_info "Translate Shell already installed"; return 0; }

    local tmp
    tmp=$(mktemp -d)
    curl -fsSLo "$tmp/trans" \
        "https://raw.githubusercontent.com/soimort/translate-shell/develop/trans"
    sudo install -m 755 "$tmp/trans" /usr/local/bin/trans
    rm -rf "$tmp"
    log_success "Translate Shell installed"
}

install_go() {
    if [[ -x /usr/local/go/bin/go ]] || command_exists go; then
        export PATH="$PATH:/usr/local/go/bin"
        log_info "Go already installed: $(go version)"
        return 0
    fi

    local version="$GO_VERSION" arch tmp
    if [[ -z "$version" ]]; then
        version=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1 | sed 's/^go//')
    fi
    arch=$(linux_arch)
    log_info "Installing Go $version ($arch)..."

    tmp=$(mktemp -d)
    curl -fsSLo "$tmp/go.tar.gz" "https://go.dev/dl/go${version}.linux-${arch}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tmp/go.tar.gz"
    rm -rf "$tmp"
    export PATH="$PATH:/usr/local/go/bin"
    log_success "Go $version installed"
}

install_pyenv() {
    log_info "Installing pyenv..."
    if [[ -d "$HOME/.pyenv" ]]; then
        log_info "pyenv already installed"
    else
        curl -fsSL https://pyenv.run | bash
        log_success "pyenv installed"
    fi
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
}

configure_fzf() {
    log_info "Configuring FZF shell integration..."

    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish --no-update-rc
    else
        log_info "FZF already configured"
    fi

    log_success "FZF configured"
}

# ============================================================================
# DATABASES
# ============================================================================
# Installs MySQL where available (Ubuntu) or MariaDB (Debian/Kali, where
# mysql-server does not exist). Sets root password to 'root'.
configure_mysql() {
    log_info "Configuring MySQL..."

    if [[ ! -x /usr/sbin/mysqld && ! -x /usr/sbin/mariadbd ]]; then
        if apt_has_package mysql-server; then
            apt_install mysql-server
        else
            log_info "mysql-server not available — installing MariaDB instead"
            apt_install mariadb-server
        fi
    fi

    local service="mysql" is_mariadb=false
    if [[ -x /usr/sbin/mariadbd ]] || systemctl cat mariadb.service >/dev/null 2>&1; then
        service="mariadb"; is_mariadb=true
    fi
    sudo systemctl enable --now "$service"

    log_info "Waiting for $service to be ready..."
    for _ in {1..30}; do
        sudo mysqladmin ping --silent 2>/dev/null && break || sleep 1
    done

    local sql
    if $is_mariadb; then
        # Keep unix_socket so `sudo mysql` still works alongside the password
        sql="ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('root') OR unix_socket; FLUSH PRIVILEGES;"
    else
        sql="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;"
    fi
    { sudo mysql -e "$sql" || sudo mysql -uroot -proot -e "SELECT 1" ; } >/dev/null 2>&1 \
        || log_warning "Could not set MySQL root password — run manually if needed."

    log_success "MySQL ($service) configured"
}

configure_postgresql() {
    log_info "Configuring PostgreSQL..."
    compgen -G "/usr/lib/postgresql/*/bin/postgres" >/dev/null \
        || apt_install postgresql postgresql-contrib

    sudo systemctl enable --now postgresql

    log_info "Waiting for PostgreSQL to be ready..."
    for _ in {1..30}; do
        pg_isready -q 2>/dev/null && break || sleep 1
    done

    # PGPASSWORD makes re-runs work once auth has been switched to md5
    local psql=(sudo -u postgres env PGPASSWORD=postgres psql -h /var/run/postgresql)
    "${psql[@]}" -c "ALTER USER postgres WITH PASSWORD 'postgres';" >/dev/null 2>&1 \
        || log_warning "Could not set postgres password — run manually if needed."

    local pg_hba
    pg_hba=$("${psql[@]}" -t -c "SHOW hba_file;" 2>/dev/null | tr -d ' \n')
    if [[ -n "$pg_hba" ]] && sudo test -f "$pg_hba"; then
        sudo test -f "$pg_hba.backup" || sudo cp "$pg_hba" "$pg_hba.backup"
        sudo sed -i 's/local\s\+all\s\+postgres\s\+peer/local   all             postgres                                md5/' "$pg_hba"
        sudo sed -i 's/local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$pg_hba"
        sudo systemctl restart postgresql
        log_success "PostgreSQL configured with password authentication"
    else
        log_warning "Could not locate pg_hba.conf — update authentication manually."
    fi
}
