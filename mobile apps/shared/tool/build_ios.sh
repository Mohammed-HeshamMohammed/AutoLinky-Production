#!/usr/bin/env bash
set -euo pipefail
exec bash "$(dirname "$0")/../../IOS app/scripts/build.sh" "$@"
