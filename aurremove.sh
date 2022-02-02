#!/bin/bash
#Package files
aurGitPackages="/home/alex/Scripts/aurgitpackages.txt"
aurPackages="/home/alex/Scripts/aurpackages.txt"
repoPackageDirectory="/mnt/aurbuild/AurmageddonRepo"
repoBuildDirectory="/mnt/aurbuild/AurmageddonBuild"

#Take user input for package to remove
read -p "Package to remove: " rmPackage

#Try to remove the package from both package lists
sed -i /"$rmPackage"/d "$aurPackages"
sed -i /"$rmPackage"/d "$aurGitPackages"

#Remove the package file from the repo
rm -v "$repoPackageDirectory"/packages/"$rmPackage"*
rm -v -r "$repoBuildDirectory"/"$rmPackage"*

echo -e "\nRemoved: $rmPackage"
