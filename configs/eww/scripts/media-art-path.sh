#!/usr/bin/env sh
cache_dir="${HOME}/.cache/eww"
mkdir -p "${cache_dir}"

# Try tidal-hifi local API first
tidal_resp="$(curl -s --max-time 2 http://localhost:47836/current 2>/dev/null)"

if [ -n "${tidal_resp}" ]; then
  local_art="$(echo "${tidal_resp}" | grep -o '"localAlbumArt":"[^"]*"' | cut -d'"' -f4)"
  if [ -n "${local_art}" ] && [ -f "${local_art}" ]; then
    echo "${local_art}"
    exit 0
  fi
fi

# Fallback: playerctl mpris:artUrl
art_url="$(playerctl metadata mpris:artUrl 2>/dev/null || true)"
[ -z "${art_url}" ] && echo "" && exit 0

case "${art_url}" in
  file://*)
    echo "${art_url#file://}"
    exit 0
    ;;
  http://*|https://*)
    hires_url="$(echo "${art_url}" | sed 's/ab67616d00001e02/ab67616d0000b273/g')"
    url_hash="$(echo "${hires_url}" | md5sum | cut -d' ' -f1)"
    cache_file="${cache_dir}/media-art-${url_hash}"
    if [ -f "${cache_file}" ] && file "${cache_file}" | grep -qiE "image|bitmap"; then
      echo "${cache_file}"
      exit 0
    fi
    curl -L -s --max-time 3 "${hires_url}" -o "${cache_file}"
    [ -f "${cache_file}" ] && echo "${cache_file}" || echo ""
    exit 0
    ;;
  *)
    echo ""
    ;;
esac
