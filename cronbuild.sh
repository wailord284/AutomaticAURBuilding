#!/bin/bash
#Automatically run the aurbuild script
cd /home/alex/Scripts
#Build aur packages
/home/alex/Scripts/aurbuild-V4.sh
wait
sleep 10s
#Upload aur packages
/home/alex/Scripts/aurupload-V2.sh
sleep 30s
