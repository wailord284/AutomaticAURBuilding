#!/bin/bash
#Colors
yellow=$(tput setaf 3) #Status
green=$(tput setaf 2) #OK
red=$(tput setaf 1) #Error
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

#Begin the build process
cd "$repoBuildDirectory"
for package in $(cat "$aurPackages" "$aurGitPackages"); do

	#Set terminal title to check for updates
	echo -en "\033]0;Checking $package for updates...\a"
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
		#If PKGBUILD DOES exist, check it before and after an aur fetch to see if its versions change
		cd "$repoBuildDirectory"
		#See if the pkgver in the packages PKGBUILD changes before/after aur fetch and if so, build a new package
		packageVersionBefore=$(grep -m1 "pkgver=" "$repoBuildDirectory"/"$package"/PKGBUILD | cut -c8-)
		packageReleaseBefore=$(grep -m1 "pkgrel=" "$repoBuildDirectory"/"$package"/PKGBUILD | cut -c8-)
		aur fetch --sync=rebase "$package"
		packageVersionAfter=$(grep -m1 "pkgver=" "$repoBuildDirectory"/"$package"/PKGBUILD | cut -c8-)
		packageReleaseAfter=$(grep -m1 "pkgrel=" "$repoBuildDirectory"/"$package"/PKGBUILD | cut -c8-)
	fi

	#Check to see if the package ends with $gitExtension and try to build it anyways
	#even if the PKGBUILD has not been updated, git packages may still have been updated on github
	#running makepkg will check to see if a new update is availible	
	gitPackageCheck=$(echo "${package: -4}")

	#Compare the versions before and after an aur fetch and build a new versions if it changed
	if [ "$packageVersionBefore" != "$packageVersionAfter" ] || [ "$packageReleaseBefore" != "$packageReleaseAfter" ] || [ "$gitPackageCheck" = "$gitExtension" ]; then
		#Create temp files to store builtPackageBefore and builtPackageAfter
		builtPackageBeforeTemp=$(mktemp)
		builtPackageAfterTemp=$(mktemp)
		oldPackage=$(mktemp)

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
