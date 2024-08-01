#!/bin/sh
# popsec.sh

export POPSEC_UID="root"

popsec_help() {
    cat << EOF

  ██████   ██████  ██████  ███████ ███████  ██████
  ██   ██ ██    ██ ██   ██ ██      ██      ██     
  ██████  ██    ██ ██████  ███████ █████   ██     
  ██      ██    ██ ██           ██ ██      ██     
  ██       ██████  ██      ███████ ███████  ██████

                    Personal OPSEC                

  popsec_install                      (one time)
  popsec_init                         + Hardware Auth (one time)

  popsec_public_gpg                   
  popsec_public_ssh                   + Hardware Check

  popsec_encrypt <dir | file>         
  popsec_decrypt <file.*.gpg>         + Hardware Auth

  popsec_sign '<text>'                + Hardware Auth
  popsec_verify <file.txt>            (BEGIN PGP SIGNATURE)

  popsec_backup                       + Hardware Auth    Personalize this!

EOF

    # Personal security script for hardware autentication with SSH and GPG to encrypt, sign, verify and backup.

    # Author: gonzo@virtualpol.com (2024-08)

    # Shamir Secret Sharing: offline generation with https://iancoleman.io/slip39/ (128 bits)  https://github.com/iancoleman/slip39
    
    # Hardware required: Trezor Safe 5 (2024) or equivalent.



    # To add uid:
    ## gpg --edit-key
    ## adduid
    ## save


    # nano ~/.bash.rc
    # . ~/popsec.sh

    # Reload this code
    . ~/popsec.sh
}


popsec_install() {
    # https://github.com/romanz/trezor-agent/blob/master/doc/INSTALL.md
    sudo apt install python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev
    pip3 install trezor-agent --break-system-packages
    
    # https://suite.trezor.io/web/bridge/
}


popsec_init() { # uid
    if [ -n "$1" ]; then
        export POPSEC_UID="$1"
    fi

    [ -z "$POPSEC_UID" ] && echo "ERROR: uid not found" && return


    # GPG init
    # rm -rf ~/.gnupg
    export GNUPGHOME=~/.gnupg/"$POPSEC_UID"
    if [ ! -d ~/.gnupg/"$POPSEC_UID" ]; then
        # https://github.com/romanz/trezor-agent/blob/master/doc/README-GPG.md
        trezor-gpg init "$POPSEC_UID" -v
    fi
    
    
    git config --global user.signingkey \
        "$(gpg --fingerprint | grep -A 1 'pub' | tail -n 1 | tr -d ' ')"
    
    git config --global commit.gpgsign true
    git config --global gpg.program "$(which gpg)"
    

    gpg --list-keys

    trezor-agent "$POPSEC_UID" -s
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
    # gpg --fingerprint | grep -A 1 'pub' | tail -n 1 | tr -d ' '
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
    echo ""
    echo "$1" | gpg --sign --recipient "$POPSEC_UID" --clearsign --digest-algo SHA256
    echo ""
    echo ""
    echo ""
}


popsec_verify() { # file.txt with BEGIN PGP...
    [ -z "$1" ] && return

    cat "$1" | gpg --verify
}


popsec_encrypt() { 
    # Check if argument is provided
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


popsec_clean() {
    sudo find . -type f -name '.DS_Store' -delete
    sudo find . -type f -name '._*' -delete
}



############## DEV ###############

popsec_pass() { # derivation experimental
    return # TODO

    [ -z "$1" ] && return
    gpg --list-keys
    
    echo "$1" \
        | gpg --clearsign --local-user "$POPSEC_UID" \
        | openssl dgst -sha256 -binary \
        | base64 \
        | head -c 16
}