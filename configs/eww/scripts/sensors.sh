#!/usr/bin/env bash
set -euo pipefail

# CPU usage (percentage, 0-100)
cpu_usage() {
  awk '{u=$2+$4; t=$2+$4+$5; if(NR==1){ou=u; ot=t} else printf "%.0f", (u-ou)*100/(t-ot)}' \
    <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat)
}

# RAM usage (percentage, 0-100)
ram_usage() {
  free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}'
}

# CPU temp (°C). Adjust the thermal zone if needed
cpu_temp() {
  local temp

  # Method 1: Search all hwmon devices for CPU temp sensors
  for hwmon in /sys/class/hwmon/hwmon*/temp*_input; do
    [[ -f "$hwmon" ]] || continue

    # Get the label file to identify the sensor
    local label_file="${hwmon%_input}_label"
    local name_file="$(dirname "$hwmon")/name"

    # Check if this is a CPU/core temp sensor
    if [[ -f "$label_file" ]]; then
      local label=$(cat "$label_file" 2>/dev/null)
      if [[ "$label" =~ ^(Package|Core|Tctl|Tdie|CPU) ]]; then
        temp=$(cat "$hwmon" 2>/dev/null)
        if [[ -n "$temp" && "$temp" -gt 0 ]]; then
          echo $(( temp / 1000 ))
          return 0
        fi
      fi
    elif [[ -f "$name_file" ]]; then
      local name=$(cat "$name_file" 2>/dev/null)
      # Look for coretemp (Intel) or k10temp (AMD)
      if [[ "$name" == "coretemp" || "$name" == "k10temp" ]]; then
        temp=$(cat "$hwmon" 2>/dev/null)
        if [[ -n "$temp" && "$temp" -gt 0 ]]; then
          echo $(( temp / 1000 ))
          return 0
        fi
      fi
    fi
  done

  # Method 2: Try thermal zones
  for zone in /sys/class/thermal/thermal_zone*/temp; do
    [[ -f "$zone" ]] || continue
    local type_file="$(dirname "$zone")/type"
    if [[ -f "$type_file" ]]; then
      local type=$(cat "$type_file" 2>/dev/null)
      # Skip ACPI and other non-CPU zones
      if [[ "$type" =~ (x86_pkg_temp|acpitz|CPU) ]]; then
        temp=$(cat "$zone" 2>/dev/null)
        if [[ -n "$temp" && "$temp" -gt 1000 ]]; then
          echo $(( temp / 1000 ))
          return 0
        fi
      fi
    fi
  done

  echo 0
}

# GPU temp: tries AMD (amdgpu), then NVIDIA, then Intel
gpu_temp() {
  # AMD
  local amd_hwmon
  amd_hwmon=$(find /sys/class/hwmon/*/name -exec grep -l amdgpu {} \; 2>/dev/null | head -1)
  if [[ -n "$amd_hwmon" ]]; then
    local dir
    dir=$(dirname "$amd_hwmon")
    if [[ -f "$dir/temp1_input" ]]; then
      echo $(( $(cat "$dir/temp1_input") / 1000 ))
      return
    fi
  fi

  # NVIDIA
  if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1
    return
  fi

  # Intel (i915)
  local intel_hwmon
  intel_hwmon=$(find /sys/class/hwmon/*/name -exec grep -l i915 {} \; 2>/dev/null | head -1)
  if [[ -n "$intel_hwmon" ]]; then
    local dir
    dir=$(dirname "$intel_hwmon")
    if [[ -f "$dir/temp1_input" ]]; then
      echo $(( $(cat "$dir/temp1_input") / 1000 ))
      return
    fi
  fi

  echo 0
}

# Bucket a value into 0-3 against three ascending thresholds.
bucket() {
  local v=$1 a=$2 b=$3 c=$4
  if (( v < a )); then echo 0
  elif (( v < b )); then echo 1
  elif (( v < c )); then echo 2
  else echo 3; fi
}

cpu=$(cpu_usage)
ram=$(ram_usage)
ct=$(cpu_temp)
gt=$(gpu_temp)
temp=$(( ct > gt ? ct : gt ))

# Overall status is whichever of CPU load, memory or heat is worst. The menu
# shows only the step; the raw numbers go in its tooltip.
level=0
for l in "$(bucket "$cpu" 20 60 90)" "$(bucket "$ram" 70 85 95)" "$(bucket "$temp" 70 80 90)"; do
  (( l > level )) && level=$l
done
status=("Idle" "Working" "Heavy load" "Overloaded")

jq -n -c \
  --argjson cpu "$cpu" \
  --argjson ram "$ram" \
  --argjson cpu_temp "$ct" \
  --argjson gpu_temp "$gt" \
  --argjson level "$level" \
  --arg status "${status[$level]}" \
  '{cpu: $cpu, ram: $ram, cpu_temp: $cpu_temp, gpu_temp: $gpu_temp, level: $level, status: $status}'
