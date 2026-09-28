#!/usr/bin/env bash
# =============================================================================
# One-time GitHub setup for pushing from CyVerse. OPTIONAL — only needed if
# you will commit and push changes. Running the notebooks needs none of this.
#
#     bash scripts/setup_github.sh
#
# WHAT IT DOES
#   * asks for your GitHub username and email
#   * creates an SSH key
#   * saves both in your PERSISTENT CyVerse folder,
#         ~/data-store/home/<your-cyverse-username>/.ssh  and  .gitconfig
#   * prints the public key for you to paste into GitHub
#
# CyVerse wipes ~/.ssh and ~/.gitconfig every analysis. Only
# ~/data-store/home/<username>/ survives (NOT the ~/data-store root), so the
# key lives there and scripts/setup_cyverse.sh copies it back each session.
# =============================================================================
set -euo pipefail

# Find the persistent Data Store home. VICE sets IPLANT_USER to the CyVerse
# username (the Linux user is always "jovyan"). Fallback: the one directory
# under ~/data-store/home that is not "shared". Override with PERSIST_DIR=.
find_persist_dir() {
    local base="$HOME/data-store/home"
    if [[ -n "${IPLANT_USER:-}" && -d "$base/$IPLANT_USER" ]]; then
        echo "$base/$IPLANT_USER"; return
    fi
    local d found=""
    for d in "$base"/*/; do
        d="${d%/}"; [[ -d "$d" && "$(basename "$d")" != "shared" ]] && found="$d"
    done
    echo "$found"
}
PERSIST_DIR="${PERSIST_DIR:-$(find_persist_dir)}"
[[ -n "$PERSIST_DIR" && -d "$PERSIST_DIR" ]] || {
    echo "ERROR: could not find your persistent folder under ~/data-store/home/." >&2
    echo "       Run with PERSIST_DIR=~/data-store/home/<your-cyverse-username>" >&2
    exit 1
}

SSH_DIR="$PERSIST_DIR/.ssh"
KEY="$SSH_DIR/id_ed25519"
GITCONFIG="$PERSIST_DIR/.gitconfig"

echo "persistent folder: $PERSIST_DIR"

if [[ ! -f "$GITCONFIG" ]]; then
    read -rp "GitHub username: " gh_user
    read -rp "GitHub email:    " gh_email
    git config --file "$GITCONFIG" user.name  "$gh_user"
    git config --file "$GITCONFIG" user.email "$gh_email"
    # The repo is cloned over https; this makes PUSH go over ssh (needs the
    # key) while clone/pull stay on anonymous https (needs nothing).
    git config --file "$GITCONFIG" url."git@github.com:".pushInsteadOf "https://github.com/"
    echo "saved $GITCONFIG"
else
    echo "using existing $GITCONFIG"
fi

if [[ ! -f "$KEY" ]]; then
    mkdir -p "$SSH_DIR"
    ssh-keygen -t ed25519 -f "$KEY" -N "" -C "cyverse-$(git config --file "$GITCONFIG" user.name)" >/dev/null
    echo "created $KEY"
else
    echo "using existing $KEY"
fi

# Put the key and config in place for THIS session too (setup_cyverse.sh
# repeats this every session). Copying matters: the Data Store mount does not
# keep the strict file permissions ssh insists on.
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
cp "$KEY" "$KEY.pub" "$HOME/.ssh/" && chmod 600 "$HOME/.ssh/id_ed25519"
ssh-keyscan -t ed25519 github.com 2>/dev/null >> "$HOME/.ssh/known_hosts"
cp "$GITCONFIG" "$HOME/.gitconfig"

cat <<EOF

Copy the whole line below and add it at https://github.com/settings/ssh/new

$(cat "$KEY.pub")

Then check it works with:   ssh -T git@github.com
EOF
