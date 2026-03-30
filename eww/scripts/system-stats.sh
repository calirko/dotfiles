#!/usr/bin/env bash

set -euo pipefail

read_temp_c() {
  local path="$1"
  if [[ -r "$path" ]]; then
    awk '{printf "%d", ($1 / 1000)}' "$path"
    return 0
  fi
  return 1
}

first_readable_from_glob() {
  local pattern="$1"
  local match
  for match in $pattern; do
    if [[ -r "$match" ]]; then
      printf "%s" "$match"
      return 0
    fi
  done
  return 1
}

cpu_temp="N/A"

if cpu_temp_file=$(first_readable_from_glob "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input"); then
  cpu_temp=$(read_temp_c "$cpu_temp_file")
elif t=$(read_temp_c "/sys/class/thermal/thermal_zone0/temp" 2>/dev/null); then
  cpu_temp="$t"
fi

if [[ "$cpu_temp" == "N/A" ]]; then
  echo " N/A"
else
  echo " ${cpu_temp}C"
fi
