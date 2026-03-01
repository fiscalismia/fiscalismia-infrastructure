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
readonly BLACK=$'\033[30m'
readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly YELLOW=$'\033[33m'
readonly BLUE=$'\033[34m'
readonly MAGENTA=$'\033[35m'
readonly CYAN=$'\033[36m'
readonly WHITE=$'\033[37m'
# Bright Text Colors
readonly BRIGHT_BLACK=$'\033[90m'
readonly BRIGHT_RED=$'\033[91m'
readonly BRIGHT_GREEN=$'\033[92m'
readonly BRIGHT_YELLOW=$'\033[93m'
readonly BRIGHT_BLUE=$'\033[94m'
readonly BRIGHT_MAGENTA=$'\033[95m'
readonly BRIGHT_CYAN=$'\033[96m'
readonly BRIGHT_WHITE=$'\033[97m'
# Background Colors
readonly BG_BLACK=$'\033[40m'
readonly BG_RED=$'\033[41m'
readonly BG_GREEN=$'\033[42m'
readonly BG_YELLOW=$'\033[43m'
readonly BG_BLUE=$'\033[44m'
readonly BG_MAGENTA=$'\033[45m'
readonly BG_CYAN=$'\033[46m'
readonly BG_WHITE=$'\033[47m'
# Bright Background Colors
readonly BG_BRIGHT_BLACK=$'\033[100m'
readonly BG_BRIGHT_RED=$'\033[101m'
readonly BG_BRIGHT_GREEN=$'\033[102m'
readonly BG_BRIGHT_YELLOW=$'\033[103m'
readonly BG_BRIGHT_BLUE=$'\033[104m'
readonly BG_BRIGHT_MAGENTA=$'\033[105m'
readonly BG_BRIGHT_CYAN=$'\033[106m'
readonly BG_BRIGHT_WHITE=$'\033[107m'
# Text Styles
readonly RESET=$'\033[0m'
readonly BOLD=$'\033[1m'  # Bold text
readonly DIM=$'\033[2m'  # Dim text
readonly ITALIC=$'\033[3m'  # Italic text
readonly UNDERLINE=$'\033[4m'  # Underlined text
readonly BLINK=$'\033[5m'  # Blinking text
readonly REVERSE=$'\033[7m'  # Reverse colors (swap fg/bg)
readonly STRIKETHROUGH=$'\033[9m'  # Strikethrough text

######## FINAL LOGGING VARIABLES
readonly ACCEPT="${BRIGHT_CYAN}"
readonly CONNECT="${BOLD}${BRIGHT_GREEN}"
readonly CLOSE="${BRIGHT_YELLOW}"
readonly MAGENTA="${BRIGHT_MAGENTA}"
readonly DEBUG="${BRIGHT_BLACK}"
readonly ERROR="${BOLD}${BG_RED}"
readonly TIMESTAMP="${DIM}${CYAN}"
readonly SOURCE_IP_PORT="${DIM}${BRIGHT_BLACK}"
readonly HTTP_INGRESS="${DIM}${YELLOW}"
readonly HTTPS_INGRESS="${DIM}${GREEN}"
readonly LINEBREAK='\n'

# haproxy termination states https://wikitech.wikimedia.org/wiki/HAProxy/session_states
readonly TS_INFO="${ITALIC}${BRIGHT_YELLOW}"
readonly TS_WARN="${ITALIC}${BRIGHT_MAGENTA}"
readonly TS_ERROR="${BOLD}${ITALIC}${BRIGHT_RED}"

podman logs --follow "$@" "${CONTAINER}" 2>&1 | sed -u \
    -e "s/\(\[[0-9][^]]*\]\)/${TIMESTAMP}\1${RESET}/g" \
    -e "s/\(:[0-9]\{1,\}\)/${SOURCE_IP_PORT}\1${RESET}/" \
    -e "s/\(http_ingress\)/${HTTP_INGRESS}\1${RESET}/" \
    -e "s/\(https_ingress\)/${HTTPS_INGRESS}\1${RESET}/" \
    -e "s/\(ACCEPT\)/${ACCEPT}\1${RESET}/g" \
    -e "s/\(TCP-REQ-CONT\)/${MAGENTA}\1${RESET}/g" \
    -e "s/\(CONNECT Tw=\)/${CONNECT}CONNECT${RESET} ${LINEBREAK}Tw=/g" \
    -e "s/\(CLOSE Tw=\)/${CLOSE}CLOSE${RESET} ${LINEBREAK}Tw=/g" \
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
