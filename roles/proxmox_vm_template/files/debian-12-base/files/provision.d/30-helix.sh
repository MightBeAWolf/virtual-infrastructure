#!/bin/bash

# Function to clean up temporary directory
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "${TMP_DIR:?}"
}

# Trap to clean up in case of error or script exit
trap cleanup EXIT INT TERM

# Create a temporary directory
TMP_DIR=$(mktemp -d -t helix-install-XXXXXXXXXX)
cd "${TMP_DIR:?}"

# If the user's .cargo bin directory exists,
# but doesn't exist in the path, update the path.
if [[ -d "${HOME}/.cargo/bin" ]] \
&& ! grep -qP "\b:?${HOME}/.cargo/bin:?\b" <<< "${PATH}"; then 
    export PATH="${HOME}/.cargo/bin:${PATH}"
fi

# Check for dependencies
dependencies=("git" "cargo" "g++")
for dep in "${dependencies[@]}"; do 
    if [ -n "$dep" ] && ! command -v $dep &> /dev/null; then
        echo "Error: Missing dependency $dep"
        exit 1
    fi
done

# Clone the Helix repository if it does not exist
git clone https://github.com/helix-editor/helix "./helix"
cd "./helix"

# Checkout the latest stable release
LATEST_RELEASE="$( git ls-remote -q --tags \
    | awk '{print $2}' \
    | xargs -I{} git log -1 --format='%at %H' {} \
    | sort -h \
    | tail -n 1 \
    | awk '{print $2}')"
git checkout "${LATEST_RELEASE:?}"

# Temporary fix for https://github.com/helix-editor/helix/pull/8932
# No longer required. Delete after some time.
# sed -i '1s/^/use-grammars = { except = ["gemini"] }\n/' languages.toml

# Build and install Helix from source
if ! cargo install --path "./helix-term" --locked; then 
    echo "Failed to install helix!"
    exit 1
fi
mv "${HOME}/.cargo/bin/hx" /usr/bin/hx
chown root:root /usr/bin/hx
chmod 755 /usr/bin/hx

# Move the runtimes into the config
mkdir -p "/etc/skel/.config/helix"
if [[ -e "/etc/skel/.config/helix/runtime" ]]; then 
    rm -rf "/etc/skel/.config/helix/runtime"
fi
mv "./runtime" "/etc/skel/.config/helix"

# Fetch and compile tree-sitter grammars
/usr/bin/hx --grammar fetch
/usr/bin/hx --grammar build

mkdir -p /usr/share/helix
mv /etc/skel/.config/helix/runtime /usr/share/helix/runtimes
chmod root:root -R /usr/share/helix
ln -s /usr/share/helix/runtimes /etc/skel/.config/helix/runtime

echo "Helix installation complete"

