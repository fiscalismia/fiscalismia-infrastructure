#!/bin/bash

export logfile="/root/sandbox_log.txt"
echo "Hello from Sandbox" > $logfile
date >> $logfile
echo "${ENV_VAR1}" >> $logfile
echo "${ENV_VAR2}" >> $logfile