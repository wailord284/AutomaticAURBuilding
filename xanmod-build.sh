#!/bin/bash
###HELPFUL RESOURCES###
#https://www.techrepublic.com/article/how-to-use-bash-associative-arrays/

#Path to store the versions information
xanmodVersionInformation=/mnt/aurbuild/kernels/xanmodVersionHistory.txt
#Build directory
xanmodBuildDirectory=/mnt/aurbuild/kernels
#Repo directory - the final package will be moved here
xanmodRepoDirectory=/mnt/aurbuild/AurmageddonRepo/packages
#The name of the xanmod kernels you want to build
xanmodKernelTypes=(linux-xanmod-edge linux-xanmod-tt)
#Set the file extension of your completed package after it is compressed
packageCompressionExtension=pkg.tar.zst
#The number of the arch you want to build (from choose-gcc-optimizations.sh)
#Set the arch name in [] followed by its code number
declare -A xanmodArchTypes
xanmodArchTypes=( [zen3]="15" [v2]="92" [v3]="93" [v4]="94")

#Check to see if xanmodVersionInformation file exists and create it if not
if [ -f "$xanmodVersionInformation" ]; then
	echo "$xanmodVersionInformation exists. Continuing..."
else
	echo "Version file does not exist, creating at $xanmodVersionInformation"
	for kernelType in "${xanmodKernelTypes[@]}" ; do
		echo "$kernelType":1 >> "$xanmodVersionInformation"
	done
	echo "Please rerun the script"
	mkdir -p "$xanmodBuildDirectory"
	mkdir -p "$xanmodRepoDirectory"
	exit 1
fi


#Get current xanmod version from AUR
for kernelType in "${xanmodKernelTypes[@]}" ; do
	#First check the current version locally and remote
	xanmodOldKernelVersion=$(grep "$kernelType" "$xanmodVersionInformation" | cut -d":" -f2)
	xanmodNewKernelVersion=$(curl -s https://aur.archlinux.org/packages/"$kernelType" | grep -o -P "(?<=$kernelType ).*(?=</h2)")
	#Check if the xanmodNewKernelVersion is greater than xanmodOldKernelVersion. If it is, then there is a new kernel
	#We use sed to strip . and - from the versions to get 1 number
	xanmodNewKernelVersionClean=$(echo "$xanmodNewKernelVersion" | sed -e 's/\.//g' -e 's/\-//g')
	xanmodOldKernelVersionClean=$(echo "$xanmodOldKernelVersion" | sed -e 's/\.//g' -e 's/\-//g')
	if [ "$xanmodNewKernelVersionClean" -gt "$xanmodOldKernelVersionClean" ]; then
		echo "New Kernel found: $kernelType:$xanmodNewKernelVersion"
		#Update the version info with this newer version
		sed -i "s/$kernelType:$xanmodOldKernelVersion/$kernelType:$xanmodNewKernelVersion/g" "$xanmodVersionInformation"
		#cd into the build directory and download the new kernel with aurutils
		cd "$xanmodBuildDirectory"
		aur fetch "$kernelType"
		#Begin the build for each arch type
		for archType in "${!xanmodArchTypes[@]}" ; do
			#cd into the cloned kernel and copy the PKGBUILD to each arch type
			cd "$xanmodBuildDirectory"/"$kernelType"
			cp PKGBUILD PKGBUILD-"$archType"
			#Update the archtype pkgbuild with the new arch type
			sed -i "s/_microarchitecture=0/_microarchitecture=${xanmodArchTypes[$archType]}/g" -i PKGBUILD-"$archType"
			sed -i "s/pkgbase=$kernelType/pkgbase=$kernelType-$archType/g" -i PKGBUILD-"$archType"
			#Build the package using makepkg
			makepkg -Cs --skippgpcheck --skipinteg --skipchecksums -p PKGBUILD-"$archType"
			#Move the final packages
			mv "$kernelType-$archType-$xanmodNewKernelVersion.$packageCompressionExtension" "$xanmodRepoDirectory"
			mv "$kernelType-$archType-headers-$xanmodNewKernelVersion.$packageCompressionExtension" "$xanmodRepoDirectory"
			#Delete the custom package build so the next time aurutils runs we get an updated one
			rm PKGBUILD-"$archType"
			#Try to remove any old kernels
			rm "$xanmodRepoDirectory"/"$kernelType-$archType-$xanmodOldKernelVersion.$packageCompressionExtension"
			rm "$xanmodRepoDirectory"/"$kernelType-$archType-headers-$xanmodOldKernelVersion.$packageCompressionExtension"
		done
	else
		echo "No new kernel found for: $kernelType"
	fi
done