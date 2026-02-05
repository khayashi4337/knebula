#!/bin/bash
# =====================================
# Nebula Certificate Generation Script
# =====================================
# Run this in WSL2 after downloading nebula-cert
#
# Usage:
#   chmod +x generate-certs.sh
#   ./generate-certs.sh

set -e

# Configuration
CA_NAME="my-nebula-network"
DURATION="87600h"  # 10 years
LIGHTHOUSE_IP="192.168.100.1"
MEMBER_IPS=("192.168.100.2" "192.168.100.3" "192.168.100.4")
MEMBER_NAMES=("member1" "member2" "member3")

echo "=== Nebula Certificate Generator ==="
echo ""

# Check if nebula-cert exists
if [ ! -f "./nebula-cert" ]; then
    echo "ERROR: nebula-cert not found in current directory"
    echo "Download from: https://github.com/slackhq/nebula/releases"
    exit 1
fi

# Create output directory
mkdir -p certs
cd certs

echo "Creating CA..."
../nebula-cert ca -name "$CA_NAME" -duration "$DURATION"

echo "Creating Lighthouse certificate..."
../nebula-cert sign -name "lighthouse" -ip "${LIGHTHOUSE_IP}/24" -duration "$DURATION"

echo "Creating member certificates..."
for i in "${!MEMBER_NAMES[@]}"; do
    name="${MEMBER_NAMES[$i]}"
    ip="${MEMBER_IPS[$i]}"
    echo "  - $name ($ip)"
    ../nebula-cert sign -name "$name" -ip "${ip}/24" -duration "$DURATION"
done

echo ""
echo "=== Certificates created in $(pwd) ==="
echo ""
ls -la
echo ""
echo "Next steps:"
echo "  1. Keep ca.key secure (NEVER distribute)"
echo "  2. Copy lighthouse.crt and lighthouse.key to Lighthouse host"
echo "  3. Copy memberX.crt, memberX.key, and ca.crt to each member"
echo ""
echo "Certificate validity: 10 years ($(date -d '+10 years' '+%Y-%m-%d' 2>/dev/null || echo 'check with nebula-cert print'))"
