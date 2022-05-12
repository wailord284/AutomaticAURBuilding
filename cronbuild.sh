#!/bin/bash
#By setting this, some packages that are built will search for ccache
#This is not required, but may speed up building for some applications
#This can also be enforced for ALL packages by enabling ccache in makepkg.conf
#export USE_CCACHE=1
#Automatically run the aurbuild script
cd /home/alex/Scripts
#Build aur packages
/home/alex/Scripts/aurbuild-V4.sh
#Build xanmod
/home/alex/Scripts/xanmod-build.sh
sleep 10s
#Upload aur packages
/home/alex/Scripts/aurupload-V2.sh
echo "Done uploading!"
sleep 30s
