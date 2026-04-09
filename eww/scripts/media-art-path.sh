#!/usr/bin/env sh

cache_dir="${HOME}/.cache/eww"
cache_file="${cache_dir}/media-art"

mkdir -p "${cache_dir}"

art_url="$(playerctl metadata mpris:artUrl 2>/dev/null || true)"

if [ -z "${art_url}" ]; then
  echo ""
  exit 0
fi

case "${art_url}" in
  file://*)
    echo "${art_url#file://}"
    exit 0
    ;;
  http://*|https://*)
    if command -v curl >/dev/null 2>&1; then
      curl -L -s --max-time 2 "${art_url}" -o "${cache_file}" && echo "${cache_file}" || echo ""
    elif command -v wget >/dev/null 2>&1; then
      wget -q -T 2 -O "${cache_file}" "${art_url}" && echo "${cache_file}" || echo ""
    else
      echo ""
    fi
    exit 0
    ;;
  *)
    echo ""
    ;;
esac
