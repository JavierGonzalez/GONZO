#!/usr/bin/env bash

### gonzo.sh ###
##################################################################
# DOCTRINE
#
# GNU/Linux Ubuntu Desktop LTS.
#
# Root of trust:
# - Trezor Safe 7 (or equivalent).
# - Seed generated offline and backed up only as physical SLIP-39 shares.
#
# Uses:
# - FIDO2/U2F: desktop login, unlock and sudo.
# - SSH: deterministic identity for servers.
# - age: deterministic Trezor identity for encryption/decryption.
# - GPG: hardware-backed signing through trezor-agent when configured.
# - LUKS: FIDO2 enrollment, configured explicitly/manually.
#
##################################################################


##################################################################
# STARTUP

AGE_RECIPIENT="age1..."

AGE_IDENTITY="# recipient: $AGE_RECIPIENT
# SLIP-0017: root
AGE-PLUGIN-TREZOR-..."

export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/trezor-agent/S.ssh"


##################################################################
# GENERIC HELPERS

_gonzo_require_command() {
    local cmd="$1"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: command not found: $cmd" >&2
        return 1
    fi
}


gonzo_security_audit() {
    local groups
    local warning=0

    groups=" $(id -nG) "

    echo "Security audit:"

    if [[ "$groups" == *" docker "* ]]; then
        echo "  WARNING: user belongs to 'docker' (root-equivalent access)."
        warning=1
    fi

    if [[ "$groups" == *" lxd "* ]]; then
        echo "  WARNING: user belongs to 'lxd' (root-equivalent access)."
        echo "           If LXD is not needed: sudo gpasswd -d \"$(id -un)\" lxd"
        warning=1
    fi

    if [[ "$groups" == *" disk "* ]]; then
        echo "  WARNING: user belongs to 'disk' (raw disk access)."
        warning=1
    fi

    if [[ -n "$SSH_AUTH_SOCK" ]]; then
        echo "  SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
    fi

    if command -v ufw >/dev/null 2>&1; then
        if sudo ufw status 2>/dev/null | grep -q '^Status: active'; then
            echo "  UFW: active"
        else
            echo "  WARNING: UFW is not active."
            warning=1
        fi
    fi

    if (( warning == 0 )); then
        echo "  No obvious local privilege bypasses detected."
    fi

    return 0
}


upgrade() {
    sudo apt-get update &&
        sudo apt-get upgrade -y &&
        sudo apt-get autoremove -y
}


ls_size() {
    du -h --max-depth=1 -- "${1:-.}" | sort -h
}


##################################################################
# INSTALL

gonzo_reload() {
    # shellcheck source=/dev/null
    source "$HOME/gonzo.sh"

    if [[ -d "$HOME/.ssh" ]]; then
        find "$HOME/.ssh" -type d -exec chmod 700 {} +
        find "$HOME/.ssh" -type f -exec chmod 600 {} +
        find "$HOME/.ssh" -type f -name '*.pub' -exec chmod 644 {} +
    fi

    sha256sum "$HOME/gonzo.sh"
}


_gonzo_pam_enable_u2f() {
    local pam_file="$1"
    local pam_line='auth sufficient pam_u2f.so authfile=/etc/u2f_mappings cue userpresence=1'
    local tmp
    local backup="${pam_file}.gonzo-backup"

    if [[ ! -f "$pam_file" ]]; then
        echo "PAM file not found, skipping: $pam_file"
        return 0
    fi

    # Keep one immutable-ish reference copy of the pre-Gonzo configuration.
    if [[ ! -e "$backup" ]]; then
        sudo cp -a -- "$pam_file" "$backup" || return 1
    fi

    tmp="$(mktemp)" || return 1

    # Canonicalize our pam_u2f rule:
    # - remove older Gonzo variants pointing at /etc/u2f_mappings
    # - insert exactly one rule immediately before common-auth
    # - password remains the fallback because the rule is "sufficient"
    if ! awk -v pam_line="$pam_line" '
        BEGIN {
            inserted = 0
        }

        $0 ~ /^[[:space:]]*auth[[:space:]]+/ &&
        $0 ~ /pam_u2f\.so/ &&
        $0 ~ /authfile=\/etc\/u2f_mappings/ {
            next
        }

        !inserted && $1 == "@include" && $2 == "common-auth" {
            print pam_line
            inserted = 1
        }

        {
            print
        }

        END {
            if (!inserted)
                exit 42
        }
    ' "$pam_file" > "$tmp"; then
        echo "Error: common-auth not found in $pam_file" >&2
        rm -f -- "$tmp"
        return 1
    fi

    # Overwrite contents while preserving the existing PAM file inode/mode.
    if ! sudo tee "$pam_file" < "$tmp" >/dev/null; then
        rm -f -- "$tmp"
        return 1
    fi

    rm -f -- "$tmp"
    echo "PAM U2F configured: $pam_file"
}


gonzo_install() {
    if [[ $EUID -eq 0 ]]; then
        echo "Error: run gonzo_install as your normal user, not as root." >&2
        return 1
    fi

    ##################################################################
    # APT

    sudo apt-get update || return 1

    sudo apt-get install -y \
        nano curl htop btop git vlc filezilla iftop iptraf-ng \
        gnome-browser-connector gnome-tweaks gnome-shell-extensions \
        libpam-u2f pamu2fcfg \
        cryptsetup fido2-tools libfido2-dev libfido2-1 \
        iotop lm-sensors cargo python3 \
        chrony ufw zstd gnupg \
        || return 1


    ##################################################################
    # SNAP

    if command -v snap >/dev/null 2>&1; then
        if ! snap list obsidian >/dev/null 2>&1; then
            sudo snap install obsidian --classic || return 1
        fi
    fi


    ##################################################################
    # GNOME

    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
    gsettings set org.gnome.SessionManager logout-prompt false


    ##################################################################
    # FIREWALL
    #
    # Never "ufw reset" here: that would destroy existing custom rules.

    sudo ufw default allow outgoing || return 1
    sudo ufw default deny incoming || return 1
    sudo ufw --force enable || return 1
    sudo ufw status verbose numbered


    ##################################################################
    # SSH

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cat > "$HOME/.ssh/config" <<'EOF_SSH_CONFIG'
Host *
    User root
EOF_SSH_CONFIG
    fi

    chmod 600 "$HOME/.ssh/config"


    ##################################################################
    # TIME SYNC

    sudo systemctl enable --now chrony || return 1
    timedatectl status


    ##################################################################
    # TREZOR
    # - SSH agent
    # - FIDO2 login/unlock
    # - FIDO2 sudo

    gonzo_install_trezor || return 1


    ##################################################################
    # OPTIONAL LUKS FIDO2 ENROLLMENT
    #
    # Keep this explicit/manual. Do not make disk-unlock changes from a
    # generic idempotent installer.
    #
    # Example:
    # sudo systemd-cryptenroll \
    #     --fido2-device=auto \
    #     /dev/nvme0n1p3


    ##################################################################
    # OPTIONAL TAILSCALE
    #
    # curl -fsSL https://tailscale.com/install.sh | sh
    # sudo tailscale up --shields-up


    ##################################################################
    # INSTALL MANUAL
    #
    # https://extensions.gnome.org/extension/1160/dash-to-panel/
    # https://extensions.gnome.org/extension/6682/astra-monitor/
    # https://extensions.gnome.org/extension/4655/date-menu-formatter/
    #
    # MMMM  y-MM-dd HH:mm

    echo
    gonzo_security_audit
}


gonzo_install_trezor() {
    if [[ $EUID -eq 0 ]]; then
        echo "Error: run gonzo_install_trezor as your normal user, not as root." >&2
        return 1
    fi

    local trezor_agent_bin
    local ssh_auth_line
    local tmp
    local combined
    local user

    user="$(id -un)"


    ##################################################################
    # DEPENDENCIES

    sudo apt-get install -y \
        libpam-u2f \
        pamu2fcfg \
        || return 1

    _gonzo_require_command trezor-agent || {
        echo "Install trezor-agent first, then run gonzo_install_trezor again." >&2
        return 1
    }


    ##################################################################
    # FIDO2 / PAM MAPPING
    #
    # Intentionally no pinverification=1.
    # Trezor user presence is enough for this threat model.

    if sudo test -f /etc/u2f_mappings &&
       sudo grep -q "^${user}:" /etc/u2f_mappings; then

        echo "Trezor FIDO2 mapping already exists for: $user"

    else
        echo
        echo "Registering Trezor FIDO2 credential for: $user"
        echo "Confirm the operation on your Trezor."
        echo

        tmp="$(mktemp)" || return 1

        if ! pamu2fcfg -u "$user" > "$tmp"; then
            rm -f -- "$tmp"
            echo "Error registering Trezor FIDO2 credential." >&2
            return 1
        fi

        if ! grep -q "^${user}:" "$tmp"; then
            rm -f -- "$tmp"
            echo "Error: invalid pamu2fcfg output." >&2
            return 1
        fi

        if sudo test -s /etc/u2f_mappings; then
            combined="$(mktemp)" || {
                rm -f -- "$tmp"
                return 1
            }

            sudo cat /etc/u2f_mappings > "$combined" || {
                rm -f -- "$tmp" "$combined"
                return 1
            }

            # Ensure exactly one separator newline.
            if [[ -s "$combined" ]] && [[ "$(tail -c 1 "$combined" 2>/dev/null)" != "" ]]; then
                printf '\n' >> "$combined"
            fi

            cat "$tmp" >> "$combined"

            sudo install \
                -o root \
                -g root \
                -m 600 \
                "$combined" \
                /etc/u2f_mappings || {
                    rm -f -- "$tmp" "$combined"
                    return 1
                }

            rm -f -- "$combined"

        else
            sudo install \
                -o root \
                -g root \
                -m 600 \
                "$tmp" \
                /etc/u2f_mappings || {
                    rm -f -- "$tmp"
                    return 1
                }
        fi

        rm -f -- "$tmp"
    fi

    sudo chown root:root /etc/u2f_mappings || return 1
    sudo chmod 600 /etc/u2f_mappings || return 1


    ##################################################################
    # PAM
    #
    # "sufficient":
    # Trezor works  -> authenticated immediately.
    # Trezor absent -> common-auth -> Unix password fallback.

    _gonzo_pam_enable_u2f /etc/pam.d/sudo || return 1
    _gonzo_pam_enable_u2f /etc/pam.d/gdm-password || return 1
    _gonzo_pam_enable_u2f /etc/pam.d/login || return 1


    ##################################################################
    # TREZOR SSH AGENT
    #

    trezor_agent_bin="$(command -v trezor-agent)"

    mkdir -p "$HOME/.config/systemd/user"

    cat > "$HOME/.config/systemd/user/trezor-ssh-agent.service" <<EOF_TREZOR_SERVICE
[Unit]
Description=Trezor SSH Agent
Requires=trezor-ssh-agent.socket

[Service]
Type=simple
Restart=always
Environment="DISPLAY=:0"
Environment="PATH=/bin:/usr/bin:/usr/local/bin:%h/.local/bin"
ExecStart=$trezor_agent_bin --foreground --sock-path %t/trezor-agent/S.ssh root
EOF_TREZOR_SERVICE

    cat > "$HOME/.config/systemd/user/trezor-ssh-agent.socket" <<'EOF_TREZOR_SOCKET'
[Unit]
Description=Trezor SSH Agent Socket

[Socket]
ListenStream=%t/trezor-agent/S.ssh
FileDescriptorName=ssh
Service=trezor-ssh-agent.service
SocketMode=0600
DirectoryMode=0700

[Install]
WantedBy=sockets.target
EOF_TREZOR_SOCKET


    ##################################################################
    # SSH_AUTH_SOCK

    ssh_auth_line='export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/trezor-agent/S.ssh"'

    touch "$HOME/.bashrc"

    if ! grep -qxF "$ssh_auth_line" "$HOME/.bashrc"; then
        printf '\n%s\n' "$ssh_auth_line" >> "$HOME/.bashrc"
    fi


    ##################################################################
    # ACTIVATE SYSTEMD USER SOCKET

    systemctl --user daemon-reload || return 1
    systemctl --user enable --now trezor-ssh-agent.socket || return 1

    # If an old service instance is already running, reload the generated
    # unit now. If it is inactive, socket activation will start it on demand.
    if systemctl --user is-active --quiet trezor-ssh-agent.service; then
        systemctl --user restart trezor-ssh-agent.service || return 1
    fi


    ##################################################################
    # CURRENT SHELL

    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/trezor-agent/S.ssh"


    ##################################################################
    # RESULT

    echo
    echo "Trezor configuration complete."
    echo
    echo "FIDO2:"
    echo "  sudo        : Trezor first, password fallback"
    echo "  GDM login   : Trezor first, password fallback"
    echo "  TTY login   : Trezor first, password fallback"
    echo "  PIN verify  : disabled by design"
    echo
    echo "SSH:"
    echo "  identity    : root"
    echo "  SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
}


########################################################################################################
# AGE

age_encrypt() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: age_encrypt <file|directory> [...]"
        return 1
    fi

    _gonzo_require_command age || return 1
    _gonzo_require_command zstd || return 1

    local input
    local output
    local parent
    local base
    local tmp
    local failed=0

    for input in "$@"; do
        input="${input%/}"

        # Ignore already encrypted files.
        if [[ -f "$input" && "$input" == *.age ]]; then
            echo "Skipping encrypted file: $input"
            continue
        fi

        if [[ -f "$input" ]]; then
            output="${input}.zst.age"
            parent="$(dirname -- "$output")"
            base="$(basename -- "$output")"

            if [[ -e "$output" ]]; then
                echo "Error: already exists: $output"
                failed=1
                continue
            fi

            tmp="$(mktemp --tmpdir="$parent" ".${base}.tmp.XXXXXX")" || {
                failed=1
                continue
            }
            chmod 600 "$tmp"

            if ! (
                set -o pipefail
                zstd -T0 -q -c -- "$input" |
                    age -r "$AGE_RECIPIENT" -o "$tmp"
            ); then
                rm -f -- "$tmp"
                echo "Error encrypting: $input" >&2
                failed=1
                continue
            fi

            if [[ ! -s "$tmp" ]]; then
                rm -f -- "$tmp"
                echo "Error: encrypted output is empty: $input" >&2
                failed=1
                continue
            fi

            mv -- "$tmp" "$output" || {
                rm -f -- "$tmp"
                failed=1
                continue
            }

            echo "$output"

        elif [[ -d "$input" ]]; then
            output="${input}.tar.zst.age"
            parent="$(dirname -- "$input")"
            base="$(basename -- "$input")"

            if [[ -e "$output" ]]; then
                echo "Error: already exists: $output"
                failed=1
                continue
            fi

            tmp="$(mktemp --tmpdir="$parent" ".${base}.tar.zst.age.tmp.XXXXXX")" || {
                failed=1
                continue
            }
            chmod 600 "$tmp"

            if ! (
                set -o pipefail
                tar -C "$parent" -cf - -- "$base" |
                    zstd -T0 -q |
                    age -r "$AGE_RECIPIENT" -o "$tmp"
            ); then
                rm -f -- "$tmp"
                echo "Error encrypting: $input" >&2
                failed=1
                continue
            fi

            if [[ ! -s "$tmp" ]]; then
                rm -f -- "$tmp"
                echo "Error: encrypted output is empty: $input" >&2
                failed=1
                continue
            fi

            mv -- "$tmp" "$output" || {
                rm -f -- "$tmp"
                failed=1
                continue
            }

            echo "$output"

        else
            echo "Error: not found: $input" >&2
            failed=1
        fi
    done

    return "$failed"
}


age_decrypt() {
    local input="${1%/}"

    if [[ -z "$input" ]]; then
        echo "Usage: age_decrypt <file.zst.age|directory.tar.zst.age>"
        return 1
    fi

    _gonzo_require_command age || return 1
    _gonzo_require_command age-plugin-trezor || return 1
    _gonzo_require_command zstd || return 1

    if [[ ! -f "$input" ]]; then
        echo "Error: not found: $input" >&2
        return 1
    fi

    ##################################################################
    # DIRECTORY

    if [[ "$input" == *.tar.zst.age ]]; then
        local parent
        local name
        local target
        local tmp_dir

        parent="$(dirname -- "$input")"
        name="$(basename -- "$input" .tar.zst.age)"
        target="$parent/$name"

        if [[ -e "$target" ]]; then
            echo "Error: already exists: $target" >&2
            return 1
        fi

        tmp_dir="$(mktemp -d "$parent/.age-decrypt.XXXXXX")" || return 1
        chmod 700 "$tmp_dir"

        if ! (
            set -o pipefail
            umask 077

            printf '%s\n' "$AGE_IDENTITY" |
                age -d -i - "$input" |
                zstd -d -q |
                tar \
                    --no-same-owner \
                    --no-same-permissions \
                    -C "$tmp_dir" \
                    -xf -
        ); then
            rm -rf -- "$tmp_dir"
            echo "Error decrypting: $input" >&2
            return 1
        fi

        if [[ ! -d "$tmp_dir/$name" ]]; then
            rm -rf -- "$tmp_dir"
            echo "Error: archive does not contain expected root directory: $name" >&2
            return 1
        fi

        if ! mv -- "$tmp_dir/$name" "$target"; then
            rm -rf -- "$tmp_dir"
            return 1
        fi

        rm -rf -- "$tmp_dir"
        echo "$target"

    ##################################################################
    # FILE

    elif [[ "$input" == *.zst.age ]]; then
        local output
        local parent
        local base
        local tmp

        output="${input%.zst.age}"
        parent="$(dirname -- "$output")"
        base="$(basename -- "$output")"

        if [[ -e "$output" ]]; then
            echo "Error: already exists: $output" >&2
            return 1
        fi

        tmp="$(mktemp --tmpdir="$parent" ".${base}.tmp.XXXXXX")" || return 1
        chmod 600 "$tmp"

        if ! (
            set -o pipefail
            umask 077

            printf '%s\n' "$AGE_IDENTITY" |
                age -d -i - "$input" |
                zstd -d -q -c > "$tmp"
        ); then
            rm -f -- "$tmp"
            echo "Error decrypting: $input" >&2
            return 1
        fi

        chmod 600 "$tmp"
        mv -- "$tmp" "$output" || {
            rm -f -- "$tmp"
            return 1
        }

        echo "$output"

    else
        echo "Error: unsupported file: $input" >&2
        return 1
    fi
}


age_backup() {
    local backup_file
    local tmp_dir
    local tmp_file

    for cmd in tar zstd age; do
        _gonzo_require_command "$cmd" || return 1
    done

    if [[ -z "$AGE_RECIPIENT" ]]; then
        echo "Error: AGE_RECIPIENT is not defined." >&2
        return 1
    fi

    backup_file="${HOME}/$(whoami)_$(date +"%Y-%m-%d").tar.zst.age"

    if [[ -e "$backup_file" ]]; then
        echo "Error: backup already exists: $backup_file" >&2
        return 1
    fi

    # Same filesystem as destination: final mv is atomic.
    tmp_dir="$(mktemp -d "${HOME}/.age_backup.XXXXXX")" || return 1
    chmod 700 "$tmp_dir"
    tmp_file="${tmp_dir}/backup.tar.zst.age"

    echo "Creating encrypted backup:"
    echo "  $backup_file"
    echo

    if ! (
        set -o pipefail
        umask 077

        tar \
            --exclude="$(whoami)_*-*-*.tar.zst.age" \
            --exclude='.age_backup.*' \
            --exclude='.bash_history' \
            --exclude='Downloads' \
            --exclude='Videos' \
            --exclude='snap' \
            --exclude='.cache' \
            --exclude='.local' \
            --exclude='.cargo' \
            --exclude='.copilot' \
            --exclude='.kpi' \
            --exclude='.dbclient' \
            --exclude='.dsh' \
            --exclude='.config/Code' \
            --exclude='.duckdb' \
            --exclude='.vscode-shared' \
            --exclude='.steampath' \
            --exclude='.steam' \
            --exclude='.npm' \
            --exclude='.gnupg' \
            --exclude='.config/google-chrome' \
            --exclude='._*' \
            --exclude='.DS_Store' \
            -cvf - \
            -C "$HOME" . |
        zstd \
            -T0 \
            -6 \
            -q |
        age \
            -r "$AGE_RECIPIENT" \
            -o "$tmp_file"
    ); then
        rm -rf -- "$tmp_dir"
        echo
        echo "Error: backup failed." >&2
        return 1
    fi

    if [[ ! -s "$tmp_file" ]]; then
        rm -rf -- "$tmp_dir"
        echo "Error: generated backup is empty." >&2
        return 1
    fi

    chmod 600 "$tmp_file"

    if ! mv -- "$tmp_file" "$backup_file"; then
        rm -rf -- "$tmp_dir"
        return 1
    fi

    rmdir -- "$tmp_dir" 2>/dev/null || true

    echo
    echo "Backup created successfully:"
    echo "  $backup_file"
    echo "  Size: $(du -h -- "$backup_file" | cut -f1)"
    echo "  SHA256: $(sha256sum -- "$backup_file" | cut -d' ' -f1)"

    return 0
}
