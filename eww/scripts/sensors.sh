#!/usr/bin/env bash
set -euo pipefail

# CPU usage (percentage, 0-100)
cpu_usage() {
  awk '{u=$2+$4; t=$2+$4+$5; if(NR==1){ou=u; ot=t} else printf "%.0f", (u-ou)*100/(t-ot)}' \
    <(grep 'cpu ' /proc/stat) <(sleep 0.3 && grep 'cpu ' /proc/stat)
}

# RAM usage (percentage, 0-100)
ram_usage() {
  free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}'
}

# CPU temp (°C) — adjust thermal zone if needed
cpu_temp() {
  local temp
  # Try hwmon first (k10temp / coretemp), fall back to thermal_zone
  if [[ -f /sys/class/hwmon/hwmon0/temp1_input ]]; then
    temp=$(cat /sys/class/hwmon/hwmon0/temp1_input)
    echo $(( temp / 1000 ))
  elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    echo $(( temp / 1000 ))
  else
    echo 0
  fi
}

# GPU temp — tries AMD (amdgpu), then NVIDIA, then Intel
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

# Output JSON
jq -n -c \
  --argjson cpu "$(cpu_usage)" \
  --argjson ram "$(ram_usage)" \
  --argjson cpu_temp "$(cpu_temp)" \
  --argjson gpu_temp "$(gpu_temp)" \
  '{cpu: $cpu, ram: $ram, cpu_temp: $cpu_temp, gpu_temp: $gpu_temp}'