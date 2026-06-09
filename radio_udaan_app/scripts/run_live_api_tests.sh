#!/usr/bin/env bash
# Live integration checks for the Dart API client (not widget tests — real HTTP).
set -euo pipefail

cd "$(dirname "$0")/.."
dart run tool/live_api_check.dart
