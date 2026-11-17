#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.1}"
FLUTTER_ROOT="${HOME}/.cache/flutter-${FLUTTER_VERSION}"
INSTALLED_FLUTTER_VERSION=""

if command -v flutter >/dev/null 2>&1; then
  INSTALLED_FLUTTER_VERSION="$(
    flutter --version --machine |
      python3 -c 'import json, sys; print(json.load(sys.stdin)["frameworkVersion"])'
  )"
fi

if [[ "$INSTALLED_FLUTTER_VERSION" != "$FLUTTER_VERSION" ]]; then
  if [[ ! -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
    archive="${TMPDIR:-/tmp}/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    mkdir -p "${HOME}/.cache"
    curl --fail --location --silent --show-error \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      --output "$archive"
    tar -xf "$archive" -C "${HOME}/.cache"
    mv "${HOME}/.cache/flutter" "$FLUTTER_ROOT"
  fi
  export PATH="${FLUTTER_ROOT}/bin:${PATH}"
fi

flutter --version
flutter pub get

build_args=(build web --release)
if [[ -n "${SUPABASE_URL:-}" ]]; then
  build_args+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
fi
if [[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  build_args+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}")
fi

flutter "${build_args[@]}"
