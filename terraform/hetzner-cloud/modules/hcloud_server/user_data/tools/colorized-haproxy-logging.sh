#!/usr/bin/env bash
# Colorized live tail of HAProxy TCP lifecycle logs
# All arguments are forwarded to podman logs.
#
# Usage:
#   ./haproxy_logs.sh            # live tail
#   ./haproxy_logs.sh --since 5m
#   ./haproxy_logs.sh --tail 100
#   etc.
#

readonly CONTAINER="haproxy"

# Text Colors
readonly BLACK="\x1b[30m"
readonly RED="\x1b[31m"
readonly GREEN="\x1b[32m"
readonly YELLOW="\x1b[33m"
readonly BLUE="\x1b[34m"
readonly MAGENTA="\x1b[35m"
readonly CYAN="\x1b[36m"
readonly WHITE="\x1b[37m"
# Bright Text Colors
readonly BRIGHT_BLACK="\x1b[90m"
readonly BRIGHT_RED="\x1b[91m"
readonly BRIGHT_GREEN="\x1b[92m"
readonly BRIGHT_YELLOW="\x1b[93m"
readonly BRIGHT_BLUE="\x1b[94m"
readonly BRIGHT_MAGENTA="\x1b[95m"
readonly BRIGHT_CYAN="\x1b[96m"
readonly BRIGHT_WHITE="\x1b[97m"
# Background Colors
readonly BG_BLACK="\x1b[40m"
readonly BG_RED="\x1b[41m"
readonly BG_GREEN="\x1b[42m"
readonly BG_YELLOW="\x1b[43m"
readonly BG_BLUE="\x1b[44m"
readonly BG_MAGENTA="\x1b[45m"
readonly BG_CYAN="\x1b[46m"
readonly BG_WHITE="\x1b[47m"
# Bright Background Colors
readonly BG_BRIGHT_BLACK="\x1b[100m"
readonly BG_BRIGHT_RED="\x1b[101m"
readonly BG_BRIGHT_GREEN="\x1b[102m"
readonly BG_BRIGHT_YELLOW="\x1b[103m"
readonly BG_BRIGHT_BLUE="\x1b[104m"
readonly BG_BRIGHT_MAGENTA="\x1b[105m"
readonly BG_BRIGHT_CYAN="\x1b[106m"
readonly BG_BRIGHT_WHITE="\x1b[107m"
# Text Styles
readonly RESET="\x1b[0m"  # Reset all formatting
readonly BOLD="\x1b[1m"  # Bold text
readonly DIM="\x1b[2m"  # Dim text
readonly ITALIC="\x1b[3m"  # Italic text
readonly UNDERLINE="\x1b[4m"  # Underlined text
readonly BLINK="\x1b[5m"  # Blinking text
readonly REVERSE="\x1b[7m"  # Reverse colors (swap fg/bg)
readonly STRIKETHROUGH="\x1b[9m"  # Strikethrough text

######## FINAL LOGGING VARIABLES
readonly RESET='\x1b[0m'
readonly ACCEPT="${BRIGHT_CYAN}"
readonly CONNECT="${BOLD}${BRIGHT_GREEN}"
readonly CLOSE="${BRIGHT_YELLOW}"
readonly MAGENTA="${BRIGHT_MAGENTA}"
readonly DEBUG="${BRIGHT_BLACK}"
readonly ERROR="${BOLD}${BG_RED}"

# haproxy termination states https://wikitech.wikimedia.org/wiki/HAProxy/session_states
readonly TS_INFO="${ITALIC}${BRIGHT_YELLOW}"
readonly TS_WARN="${ITALIC}${BRIGHT_MAGENTA}"
readonly TS_ERROR="${BOLD}${ITALIC}${BRIGHT_RED}"

podman logs --follow "$@" "${CONTAINER}" 2>&1 | sed -u \
    -e "s/\(ACCEPT\)/${ACCEPT}\1${RESET}/g" \
    -e "s/\(TCP-REQ-CONT\)/${MAGENTA}\1${RESET}/g" \
    -e "s/\(CONNECT Tw=\)/${CONNECT}CONNECT${RESET} Tw=/g" \
    -e "s/\(CLOSE Tw=\)/${CLOSE}CLOSE${RESET} Tw=/g" \
    -e "s/\(ERROR Tw=\)/${ERROR}ERROR${RESET} Tw=/g" \
    -e "s/\(silent-drop\)/${ERROR}\1${RESET}/g" \
    \
    -e "s/\(ts=CD\)/ts=${TS_INFO}CD${RESET}/g" \
    -e "s/\(ts=LR\)/ts=${TS_INFO}LR${RESET}/g" \
    -e "s/\(ts=PR\)/ts=${TS_INFO}PR${RESET}/g" \
    \
    -e "s/\(ts=CC\)/ts=${TS_WARN}CC${RESET}/g" \
    -e "s/\(ts=cD\)/ts=${TS_WARN}cD${RESET}/g" \
    -e "s/\(ts=cR\)/ts=${TS_WARN}CR${RESET}/g" \
    -e "s/\(ts=sC\)/ts=${TS_WARN}sC${RESET}/g" \
    -e "s/\(ts=sD\)/ts=${TS_WARN}sD${RESET}/g" \
    -e "s/\(ts=sQ\)/ts=${TS_WARN}sQ${RESET}/g" \
    \
    -e "s/\(ts=SC\)/ts=${TS_ERROR}SC${RESET}/g" \
    -e "s/\(ts=SD\)/ts=${TS_ERROR}SD${RESET}/g" \
    -e "s/\(ts=SH\)/ts=${TS_ERROR}SH${RESET}/g" \
    -e "s/\(ts=PC\)/ts=${TS_ERROR}PC${RESET}/g" \
    -e "s/\(ts=PD\)/ts=${TS_ERROR}PD${RESET}/g" \
    -e "s/\(ts=PH\)/ts=${TS_ERROR}PH${RESET}/g" \
    \
    -e "s/\(Tt=[0-9]*\)/${DEBUG}\1${RESET}/g" \
    -e "s/\(B=[0-9]*\)/${DEBUG}\1${RESET}/g"
