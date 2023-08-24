#!/bin/bash -e
self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

echo "Checking HTTP proxy setup..."

# Make sure that proxy env vars are inherited by sudo sessions
echo 'Defaults    env_keep += " http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY "' | sudo tee /etc/sudoers.d/proxy  > /dev/null
sudo chown root:root /etc/sudoers.d/proxy
sudo chmod go-rwx /etc/sudoers.d/proxy

# replace proxy envvars in /etc/environment  (required, because ansible uses /bin/sh and not bash)
if [ -f /etc/environment ]; then
    sudo sed --in-place '/_proxy=/I d' /etc/environment
fi

# sensible defaults for *_proxy
if [ -n "$http_proxy" -o -n "$https_proxy" ]; then
    export http_proxy=${http_proxy:-${https_proxy}}
    export https_proxy=${https_proxy:-${http_proxy}}
    export no_proxy="${no_proxy:-127.0.0.1,localhost,.cluster,.local,.svc,.novalocal,.nsn-net.net,.nsn-rdnet.net,.nokia.net,.xip.io,169.254.169.254}"

    # replace proxy envvars in /etc/environment
    cat << THEEND | sudo tee -a  /etc/environment > /dev/null
    http_proxy="$http_proxy"
    https_proxy="$https_proxy"
    no_proxy="$no_proxy"
THEEND    
fi

# sensible defaults for *_PROXY
if [ -n "$HTTP_PROXY" -o -n "$HTTPS_PROXY" ]; then
    export HTTP_PROXY=${HTTP_PROXY:-${HTTPS_PROXY}}
    export HTTPS_PROXY=${HTTPS_PROXY:-${HTTP_PROXY}}
    export NO_PROXY="${NO_PROXY:-127.0.0.1,localhost,.cluster,.local,.svc,.novalocal,.nsn-net.net,.nsn-rdnet.net,.nokia.net,.xip.io,169.254.169.254}"

    # replace proxy envvars in /etc/environment
    cat << THEEND | sudo tee -a  /etc/environment > /dev/null
    HTTP_PROXY="$HTTP_PROXY"
    HTTPS_PROXY="$HTTPS_PROXY"
    NO_PROXY="$NO_PROXY"
THEEND
fi

echo "Dwonloading and starting the init script..."

curl https://raw.githubusercontent.com/nokia/nephio-test-infra/nokia-intranet/e2e/provision/init.sh |  \
sudo \
  NEPHIO_DEBUG="${NEPHIO_DEBUG:-false}" \
  NEPHIO_USER="${NEPHIO_USER:-${USER:-ubuntu}}" \
  NEPHIO_REPO="https://github.com/nokia/nephio-test-infra.git" \
  NEPHIO_BRANCH="nokia-intranet" \
  DOCKER_REGISTRY_MIRRORS='["https://docker-registry-remote.artifactory-espoo1.int.net.nokia.com","https://docker-registry-remote.artifactory-espoo2.int.net.nokia.com"]' \
  bash
