#!/bin/bash
###HELPFUL RESOURCES###
#https://www.techrepublic.com/article/how-to-use-bash-associative-arrays/
#https://aur.archlinux.org/packages/linux-xanmod-edge

#Path to store the versions information
xanmodVersionInformation=/mnt/aurbuild/kernels/xanmodVersionHistory.txt
#Build directory
xanmodBuildDirectory=/mnt/aurbuild/kernels
#Repo directory - the final package will be moved here
xanmodRepoDirectory=/mnt/aurbuild/AurmageddonRepo/packages
#The name of the xanmod kernels you want to build
xanmodKernelTypes=(linux-xanmod-edge linux-xanmod-tt)
#The number of the arch you want to build (from choose-gcc-optimizations.sh)
#Set the arch name in [] followed by its code number
declare -A xanmodArchTypes
xanmodArchTypes=([generic]="0" [zen3]="15" [v3]="93")
#Set what config type to use. This was added in 5.17.6. Defaults to -v2
#Supposedly this is overwritten by custom archtypes, but in testing that doesn't seem to be the case
#For now we set this to not have any v2 or v3 options
xanmodBuildOptionConfig=config_x86-64
#Set to y (yes) or n (no) to enable or disable NUMA. This is enabled by default and may break CUDA/NvEnc if set to no
xanmodBuildOptionNuma=n
#Set to y (yes) or n (no) to enable or disable tracers. This is enabled by default and will limit debug functions if no
xanmodBuildOptionTracers=n
#Set to y (yes) or n (no) to enable or disable module compression. This is disabled by default but may save disk space if enabled
xanmodBuildOptionCompression=y
#Set to gcc or clang for the compiler. Clang may have issues. GCC is default
xanmodBuildOptionCompiler=gcc
#Set the path to your makepkg conf. This is useful for enabling ccache only for these kernels while the rest of the build does not
#The package extension will also be grabbed from this file
#You can adjust any settings in here to change how packages are created or compressed
makepkgConfFile=/home/alex/Scripts/makepkg.conf
#Get the package compression extension from the makepkg conf file
packageCompressionExtension=$(grep PKGEXT "$makepkgConfFile" | cut -d"'" -f2)


#Check to see if xanmodVersionInformation file exists and create it if not
if [ -f "$xanmodVersionInformation" ]; then
	echo "$xanmodVersionInformation exists. Continuing..."
else
	#Make the directories just in case. Mainly used this while testing so I could nuke the build directories
	mkdir -p "$xanmodBuildDirectory"
	mkdir -p "$xanmodRepoDirectory"
	echo "Version file does not exist, creating at $xanmodVersionInformation"
	for kernelType in "${xanmodKernelTypes[@]}" ; do
		echo "$kernelType":1 >> "$xanmodVersionInformation"
	done
	echo "Version file created, continuing..."
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
		aur fetch --sync=rebase "$kernelType"
		#Begin the build for each arch type
		for archType in "${!xanmodArchTypes[@]}" ; do
			#cd into the cloned kernel and copy the PKGBUILD to each arch type
			cd "$xanmodBuildDirectory"/"$kernelType"
			cp PKGBUILD PKGBUILD-"$archType"
			#Update the archtype pkgbuild with the new arch type
			sed -i "s/_microarchitecture=0/_microarchitecture=${xanmodArchTypes[$archType]}/g" PKGBUILD-"$archType"
			sed -i "s/pkgbase=$kernelType/pkgbase=$kernelType-$archType/g" PKGBUILD-"$archType"
			sed -i "s/_config=config_x86-64-v2/_config=$xanmodBuildOptionConfig/g" -i PKGBUILD-"$archType"
			#Update the pkgbuild with the xanmodBuildOptions
			if [ "$xanmodBuildOptionNuma" = n ]; then
				sed -i "s/use_numa=y/use_numa=n/g" -i PKGBUILD-"$archType"
			fi
			if [ "$xanmodBuildOptionTracers" = n ]; then
				sed -i "s/use_tracers=y/use_tracers=n/g" -i PKGBUILD-"$archType"
			fi
			if [ "$xanmodBuildOptionCompiler" = clang ]; then
				sed -i "s/_compiler=gcc/_compiler=clang/g" -i PKGBUILD-"$archType"
			fi
			if [ "$xanmodBuildOptionCompression" = y ]; then
				sed -i "s/_compress_modules=n/_compress_modules=y/g" -i PKGBUILD-"$archType"
			fi
			#Build the package using makepkg
			makepkg -Cs --conf "$makepkgConfFile" --skippgpcheck -p PKGBUILD-"$archType"
			#Move the final packages
			mv "$kernelType-$archType-$xanmodNewKernelVersion-x86_64.$packageCompressionExtension" "$xanmodRepoDirectory"
			mv "$kernelType-$archType-headers-$xanmodNewKernelVersion-x86_64.$packageCompressionExtension" "$xanmodRepoDirectory"
			#Delete the custom package build so the next time aurutils runs we get an updated one
			rm PKGBUILD-"$archType"
			#Try to remove any old kernels
			rm "$xanmodRepoDirectory"/"$kernelType-$archType-$xanmodOldKernelVersion-x86_64.$packageCompressionExtension"
			rm "$xanmodRepoDirectory"/"$kernelType-$archType-headers-$xanmodOldKernelVersion-x86_64.$packageCompressionExtension"
		done
	else
		echo "No new kernel found for: $kernelType"
	fi
done