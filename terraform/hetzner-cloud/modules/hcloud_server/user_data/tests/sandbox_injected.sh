#!/bin/bash

# INFO: Can be injected into cloud-config.yml files as base64 encoded env var as a parameter of templatefile.
# after using base64encode(filepath) and saving a a local variable

export logfile="/root/sandbox_injected_log.txt"
echo "Hello from Sandbox" > $logfile
date >> $logfile
echo "${ENV_VAR1}" >> $logfile
echo "${ENV_VAR2}" >> $logfile