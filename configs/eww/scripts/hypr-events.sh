#!/usr/bin/env bash
# Stream Hyprland's IPC event socket (socket2) on stdout, one event per line.
#
# Hyprland has no CLI for tailing events, so this needs a unix-socket client.
# socat is the usual pick but isn't part of a base Arch install -- and when
# it's missing the watcher scripts print their first snapshot and then exit
# immediately, which silently freezes the bar's workspace / window-title /
# keyboard-layout state. So try socat, then nmap's ncat, then a netcat that
# understands -U.

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/" 2>/dev/null | grep -v '\.lock' | head -1)}"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${SIG}/.socket2.sock"

if command -v socat >/dev/null 2>&1; then
    exec socat -u UNIX-CONNECT:"$SOCK" STDOUT
elif command -v ncat >/dev/null 2>&1; then
    exec ncat -U "$SOCK"
elif command -v nc >/dev/null 2>&1; then
    exec nc -U "$SOCK"
fi

echo "hypr-events.sh: need socat, ncat or a netcat with -U to read $SOCK" >&2
exit 1
