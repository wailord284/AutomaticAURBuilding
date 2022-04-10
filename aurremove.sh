#!/bin/bash
#Function to check array contents
#https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
arrayContains () {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

#Package files
aurGitPackages="/home/alex/Scripts/aurgitpackages.txt"
aurPackages="/home/alex/Scripts/aurpackages.txt"
repoPackageDirectory="/mnt/aurbuild/AurmageddonRepo/packages"
repoBuildDirectory="/mnt/aurbuild/AurmageddonBuild"
#Create array of both package files
mapfile -t allPackages < <(cat $aurPackages $aurGitPackages | sort -u)


#Take user input for package to remove
read -r -p "Package to remove: " rmPackage

#Check if the package exists before doing anything
arrayContains "$rmPackage" "${allPackages[@]}"
if [ $? = 0 ]; then
	#Remove the package from both package lists if rmPackage is in allPackages
	sed -i /"$rmPackage"/d "$aurPackages"
	sed -i /"$rmPackage"/d "$aurGitPackages"

	echo -e "\nThe following items have been removed: "
	#Remove the package and build files from the repo
	rm -v "$repoPackageDirectory/$rmPackage"*
	rm -r "$repoBuildDirectory/$rmPackage"*
	echo "$repoBuildDirectory/$rmPackage"
else
	echo "$rmPackage cannot be found in $aurPackages or $aurGitPackages"
fi
