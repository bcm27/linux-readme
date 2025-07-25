#!/bin/bash

# This script shall backup important configuration files

# backup baqpaq configuration profiles

cp /home/bjorn.mathisen/.config/baqpaq /backup.$(date +%Y%m%d_%H%M%S)