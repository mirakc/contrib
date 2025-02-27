set -eu

DEBIAN=debian13
ARCH=amd64

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl jq

JQ_FILTER=$(cat <<EOF
.assets[].browser_download_url | select(. | test("tsduck_.*\\\\.${DEBIAN}_${ARCH}\\\\..*"))
EOF
)

API_BASE_URL='https://api.github.com/repos/tsduck/tsduck'
LATEST_URL=$(curl "$API_BASE_URL/releases/latest" -sG | jq -r "$JQ_FILTER")

curl "$LATEST_URL" -fsSL >/tmp/tsduck.deb
apt install -y /tmp/tsduck.deb

# tests
tsversion

# cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/tmp/*
rm -rf /tmp/*
