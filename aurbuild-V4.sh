#!/bin/bash
#Colors
yellow=$(tput setaf 3) #Status
green=$(tput setaf 2) #OK
reset=$(tput sgr 0) #Remove set color
line="====================================================================="
#Setup directories for building and location to files
#Make sure you create folder database and packages in repoPackageDirectory
###Do not put a trailing / at the end of the build and repo directory###
repoBuildDirectory="/mnt/aurbuild/AurmageddonBuild"
repoPackageDirectory="/mnt/aurbuild/AurmageddonRepo"
#Path to a text file containing all packages to build
aurPackages="/home/alex/Scripts/aurpackages.txt"
#Path to a text file containing all git packages to build ending with -git
aurGitPackages="/home/alex/Scripts/aurgitpackages.txt"
#Set the git package extension. This is almost always -git
gitExtension="-git"
#Amount of time to wait before checking a package for updates to prevent 429 error
aurUpdateDelay=4s

#Begin the build process
cd "$repoBuildDirectory"
for package in $(cat "$aurPackages" "$aurGitPackages"); do
	#Output checking message
	echo -e "$yellow$line\nChecking $package for updates...\n$line$reset"
	#Wait for the delay
	sleep "$aurUpdateDelay"
	#Check to see if the PKGBUILD file does NOT exist
	if [ ! -f "$repoBuildDirectory"/"$package"/PKGBUILD ]; then
		echo -e "$yellow$line\n$package does not exist, it will be built for the first time\n$line$reset"

		#Download the package
		cd "$repoBuildDirectory"
		aur fetch --sync=rebase "$package"
		#Build the package
		cd "$repoBuildDirectory"/"$package"
		makepkg -Cs --noconfirm --skipchecksums --skippgpcheck
		echo -e "$green$line\n$package has been built for the first time\n$line$reset"
		#Copy the packages(s) one at a time to the repoDirectory
		for builtPackage in $(ls -Art | grep ".pkg.tar.zst"); do
			tput setaf 2; cp -r -v "$repoBuildDirectory"/"$package"/"$builtPackage" "$repoPackageDirectory"/packages
		done
	else
		#If PKGBUILD DOES exist, check the PKGBUILD versions, then grab a version from the AUR using curl to compare
		cd "$repoBuildDirectory"
		#See if the pkgver and pkgrel in the packages PKGBUILD
		packageVersionCurrent=$(grep -m1 "pkgver=" "$repoBuildDirectory"/"$package"/PKGBUILD | cut -d"=" -f2 | cut -d" " -f1)
		packageReleaseCurrent=$(grep -m1 "pkgrel=" "$repoBuildDirectory"/"$package"/PKGBUILD | cut -d"=" -f2 | cut -d" " -f1)
		#Make $packageCurrent a complete version number
		packageCurrent=$packageVersionCurrent-$packageReleaseCurrent
		#Check for a new version and then make the current and new versions just a number
		packageNewVersionCheck=$(curl -s https://aur.archlinux.org/packages/"$package" | grep -m1 "Package Details: $package" | rev | cut -c6- | cut -d" " -f1 | rev | cut -d":" -f2)
		packageCurrentClean=$(echo "$packageCurrent" |  sed 's/[^0-9]*//g')
		packageNewVersionClean=$(echo $packageNewVersionCheck | sed 's/[^0-9]*//g')
	fi

	#Check to see if the package ends with $gitExtension and try to build it anyways
	#even if the PKGBUILD has not been updated, git packages may still have been updated on github
	#running makepkg will check to see if a new update is availible
	gitPackageCheck=$(echo "${package: -4}")

	#Compare the current version from the PKGBUILD to the version from the AUR website
	if [ "$packageNewVersionClean" != "$packageCurrentClean" ] || [ "$gitPackageCheck" = "$gitExtension" ]; then
		#Since there's a new package, run aur fetch to update the PKGBUILD
		aur fetch --sync=reset "$package"
		aur fetch --sync=rebase "$package"
		#Create temp files to store builtPackageBefore and builtPackageAfter
		builtPackageBeforeTemp=$(mktemp)
		builtPackageAfterTemp=$(mktemp)
		oldPackage=$(mktemp)
		#Change into the package directory to start building
		cd "$repoBuildDirectory"/"$package"
		#Check for built packages before and after running makepkg
		echo $(ls -Art | grep ".pkg.tar.zst" | tr " " "\n") > "$builtPackageBeforeTemp"
		makepkg -Cs --noconfirm --skipchecksums --skippgpcheck
		echo $(ls -Art | grep ".pkg.tar.zst" | tr " " "\n") > "$builtPackageAfterTemp"
		#If the built packages are not equal after running makepkg, find the difference (new package)
		if [ "$(cat "$builtPackageBeforeTemp")" != "$(cat "$builtPackageAfterTemp")" ]; then
			#Remove all before packages from the after package list to get only new packages
			for builtBefore in $(cat "$builtPackageBeforeTemp" | tr " " "\n"); do
				sed -e s/"$builtBefore"//g -i "$builtPackageAfterTemp"
			done

			#Copy the new packages ($builtAfter) from builtPackageAfterTemp
			echo -e "$green\nNew package(s) built:\n$reset"
			for builtAfter in $(cat "$builtPackageAfterTemp"); do
				tput setaf 2; cp -r -v "$repoBuildDirectory"/"$package"/"$builtAfter" "$repoPackageDirectory"/packages
			done

			#Remove the old packages
			sort -u "$builtPackageBeforeTemp" "$builtPackageAfterTemp" > "$oldPackage"
			echo -e "$yellow$line\nRemoving old package(s):\n$reset"

			#Remove the newly generated packages from oldPackage (leaves only the packages existing before running makepkg)
			for removeAfterPackages in $(cat "$builtPackageAfterTemp" | tr " " "\n"); do
				sed -e s/"$removeAfterPackages"//g -i "$oldPackage"
			done

			#Finally delete the old packages from builtPackageBeforeTemp
			for toDelete in $(cat "$oldPackage"); do
				echo "$yellow""$toDelete""$reset"
				rm -r "$repoBuildDirectory"/"$package"/"$toDelete" "$repoPackageDirectory"/packages/"$toDelete"
			done
			echo -e "$yellow$line\n$reset"

		#If the built package is equal before and after makepkg, then no package has been built
		elif [ "$(cat "$builtPackageBeforeTemp")" = "$(cat "$builtPackageAfterTemp")" ]; then
			echo -e "$yellow$line\nNo new packages built\n$line$reset"
		fi

		#Cleanup - Delete the temp files
		rm -r "$builtPackageBeforeTemp" "$builtPackageAfterTemp" "$oldPackage"

		#If the versions do match do nothing
	elif [ "$packageVersionBefore" = "$packageVersionAfter" ] && [ "$packageReleaseBefore" = "$packageReleaseAfter" ]; then
		echo -e "$yellow$line\nThere are no updates for $package\n$line$reset"
	fi

cd
done
#Upload the packages to the repo with aurupload.sh
