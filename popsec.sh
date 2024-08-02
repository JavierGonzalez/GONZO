#!/bin/sh

popsec_help() {
    cat << EOF

  ██████   ██████  ██████  ███████ ███████  ██████
  ██   ██ ██    ██ ██   ██ ██      ██      ██     
  ██████  ██    ██ ██████  ███████ █████   ██     
  ██      ██    ██ ██           ██ ██      ██     
  ██       ██████  ██      ███████ ███████  ██████

                    Personal OPSEC                

  popsec_install
  popsec_init                         + Hardware Auth (one time)

  popsec_public_gpg                   
  popsec_public_ssh                   + Hardware Check
  popsec_adduid '<realname>' <email>  + Hardware Auth

  popsec_encrypt <dir | file>         
  popsec_decrypt <file.*.gpg>         + Hardware Auth

  popsec_sign '<text>'                + Hardware Auth
  popsec_verify <file.txt>            (BEGIN PGP SIGNATURE)

EOF

    # A Personal OPeration SECurity script for hardware autentication.
    # Allowing universal autentication (SSH, GPG, encrypt, sign, FIDO2). 
    # Trying just one hardware-protected masterkey for everything.


    # Tested in Ubuntu 24.04 and MacOS 10.15 with Trezor Model T (good), Trezor Safe 3 and Trezor Safe 5 (best).
    # Author: gonzo@virtualpol.com  A3AD 4AC5 F252 8190 65A5 75A0 B9C3 5FBF 43B3 19C2
    # https://github.com/JavierGonzalez/GONZO/blob/master/popsec.sh

    # Based in trezor-agent https://github.com/romanz/trezor-agent by Roman Zeyde.

    # Recomended:
    # Shamir Secret Sharing: offline generated with https://iancoleman.io/slip39/ (128 bits, 20 words)  https://github.com/iancoleman/slip39
    # Hardware: Trezor Safe 5 (2024) or equivalent.


    # Add this next line in: .bash.rc (Linux) or .zshrc (MacOS):
    source ~/popsec.sh
}

export POPSEC_UID="root" # Default masterkey derivation (recipient) for SSH and GPG.

export GNUPGHOME=~/.gnupg/"$POPSEC_UID"


popsec_install() {
    if [ ! -f "$HOME/popsec.sh" ]; then
        echo "ERROR: $HOME/popsec.sh file does not exist."
        return 1
    fi

    # https://suite.trezor.io/web/bridge/

    # https://github.com/romanz/trezor-agent/blob/master/doc/INSTALL.md
    sudo apt install python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev
    pip3 install trezor-agent --break-system-packages

    trezor-agent --version

    echo ""
    echo ""
    echo " Add this next line in .bash.rc (Linux) or .zshrc (MacOS):"
    echo "   source ~/popsec.sh"
    echo ""
}


popsec_init() { # uid
    if [ -n "$1" ]; then
        export POPSEC_UID="$1"
    fi

    [ -z "$POPSEC_UID" ] && echo "ERROR: uid not found" && return


    # trezor-gpg init
    export GNUPGHOME=~/.gnupg/"$POPSEC_UID"
    if [ ! -d ~/.gnupg/"$POPSEC_UID" ]; then
        # https://github.com/romanz/trezor-agent/blob/master/doc/README-GPG.md
        trezor-gpg init "$POPSEC_UID" --verbose
    fi
    
    
    git config --global user.signingkey "$(popsec_fingerprint)"
    git config --global commit.gpgsign true
    git config --global gpg.program "$(which gpg)"
    

    gpg --list-keys

    trezor-agent "$POPSEC_UID" --shell
}


popsec_adduid() { # realname email
    [ -z "$1" ] && return
    [ -z "$2" ] && return

    # Editar la clave GPG para añadir el UID
    gpg --command-fd 0 --edit-key "$(popsec_fingerprint)" <<EOF
adduid
$1
$2

O
save
EOF

    popsec_public_gpg
}


popsec_reset() {
    rm -rf ~/.gnupg
}


popsec_public() {
    popsec_public_gpg
    popsec_public_ssh
}


popsec_public_gpg() {
    echo ""
    gpg --list-keys
    echo ""
    gpg --armor --export
    echo ""
}


popsec_public_ssh() { # user
    # https://github.com/romanz/trezor-agent/blob/master/doc/README-SSH.md
    trezor-agent "$POPSEC_UID"
}


popsec_sign() { # text
    [ -z "$1" ] && return

    gpg --list-keys
    echo ""
    echo ""
    echo "$1" | gpg --sign --recipient "$POPSEC_UID" --clearsign --digest-algo SHA256
    echo ""
    echo ""
}


popsec_verify() { # file.txt with BEGIN PGP...
    [ -z "$1" ] && return

    cat "$1" | gpg --verify
}


popsec_encrypt() { 
    if [ -z "$1" ]; then
        echo "Error: No file or directory specified."
        return 1
    fi
    
    # Ensure the POPSEC_UID variable is set
    if [ -z "$POPSEC_UID" ]; then
        echo "Error: POPSEC_UID is not set."
        return 1
    fi

    gpg --list-keys
    
    # Check if the input is a file or a directory
    if [ -f "$1" ]; then
        # Encrypt file
        gpg --encrypt --recipient "$POPSEC_UID" \
            --cipher-algo AES256 \
            --compress-algo ZIP \
            --digest-algo SHA256 \
            --compress-level 6 \
            "$1"
        
        if [ $? -ne 0 ]; then
            echo "Error: File encryption failed."
            return 1
        fi
        
        shasum -a 256 "$1"
        shasum -a 256 "$1.gpg"
    elif [ -d "$1" ]; then
        # Encrypt directory
        tar -vc "$(basename "$1")" \
            | gpg --encrypt \
                --recipient "$POPSEC_UID" \
                --cipher-algo AES256 \
                --compress-algo ZIP \
                --digest-algo SHA256 \
                --compress-level 6 \
                --output "$(basename "$1")_$(date +"%Y-%m-%d").tar.gpg"
        
        if [ $? -ne 0 ]; then
            echo "Error: Directory encryption failed."
            return 1
        fi

        echo "$(basename "$1")_$(date +"%Y-%m-%d").tar.gpg"
    else
        echo "Error: $1 is neither a file nor a directory."
        return 1
    fi
}


popsec_decrypt() { # file or directory *.tar.gpg or *.gpg
    # Check if argument is provided
    [ -z "$1" ] && { echo "Error: No file provided"; return 1; }
    
    # Check if file exists
    [ ! -f "$1" ] && { echo "Error: File does not exist"; return 1; }
    
    # Determine if it's a tar.gpg or just a gpg file
    if [[ "$1" == *.tar.gpg ]]; then
        # Decrypt and extract tar.gpg
        gpg --decrypt "$1" | tar vx || { echo "Error: Decryption or extraction failed"; return 1; }
    elif [[ "$1" == *.gpg ]]; then
        # Decrypt regular gpg file
        gpg --decrypt --output "${1%.gpg}" "$1" || { echo "Error: Decryption failed"; return 1; }
    else
        echo "Error: Unsupported file type"; return 1;
    fi
    
    # Calculate and display shasum
    shasum -a 256 "$1" || { echo "Error: Failed to calculate shasum for $1"; return 1; }
    
    if [[ "$1" == *.gpg ]]; then
        shasum -a 256 "${1%.gpg}" || { echo "Error: Failed to calculate shasum for ${1%.gpg}"; return 1; }
    fi
    
    echo "Decryption and verification completed successfully"
}


popsec_clean() {
    sudo find . -type f -name '.DS_Store' -delete
    sudo find . -type f -name '._*' -delete
}

popsec_fingerprint() {
    gpg --list-keys | grep -A 1 'pub' | tail -n 1 | tr -d ' '
}



############## DEV ###############


popsec_backup() { 
    gpg --list-keys

    # Define backup file name
    backup_file="${HOME}/$(whoami)_$(date +"%Y-%m-%d").tar.gpg"

    # Create the tarball and encrypt it with gpg
    tar --exclude="$(whoami)_*-*-*.tar.gpg" \
        --exclude='.bash_history' \
        --exclude='Downloads' \
        --exclude='Videos' \
        --exclude='snap' \
        --exclude='.cache' \
        --exclude='.local' \
        --exclude='.gnupg' \
        --exclude='.config/google-chrome' \
        --exclude='._*' \
        --exclude='.DS_Store' \
        -cvf - -C "$HOME" . \
        | gpg --encrypt --recipient "$POPSEC_UID" \
            --cipher-algo AES256 \
            --compress-algo ZIP \
            --digest-algo SHA256 \
            --compress-level 8 \
            --output "$backup_file" 2>/tmp/gpg_error.log

    # Check if tar command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: tar command failed. Check /tmp/tar_error.log for details." >&2
        return 1
    fi

    # Check if gpg command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: gpg command failed. Check /tmp/gpg_error.log for details." >&2
        return 1
    fi

    # Print the location of the backup file
    echo "Backup created successfully: $backup_file"
    return 0
}