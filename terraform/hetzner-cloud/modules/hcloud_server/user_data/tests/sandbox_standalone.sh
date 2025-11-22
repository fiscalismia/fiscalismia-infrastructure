#!/bin/bash

# INFO: Can be executed directly via cloudinit_config.part as text/x-shellscript

export logfile="/root/sandbox_standalone_log.txt"
echo "Hello from Sandbox" > $logfile
date >> $logfile
echo "${ENV_VAR1}" >> $logfile
echo "${ENV_VAR2}" >> $logfile