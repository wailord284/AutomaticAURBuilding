#!/bin/bash
aurGitPackages="/home/alex/Scripts/aurgitpackages.txt"
aurPackages="/home/alex/Scripts/aurpackages.txt"
repoPackageDirectory="/mnt/aurbuild/AurmageddonRepo"
sortFile=$(mktemp)

#Git
cat "$aurGitPackages" | sort -u > "$sortFile"
#Override the old file with the new one
cat "$sortFile" > "$aurGitPackages"

#Normal - writing to this will overwrite the old stuff due to a single >
cat "$aurPackages" | sort -u > "$sortFile"
#Override the old file with the new one
cat "$sortFile" > "$aurPackages"

#Remove temp file
rm "$sortFile"

echo "Package files sorted"
