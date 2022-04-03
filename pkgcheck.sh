#!/bin/bash
#Set output file to store duplicated packages
pkgOutput="/home/alex/pkgdupe.txt"
repoName="aurmageddon"
line="============================================================================="
#Get a list of all packages in the aurmageddon repo
totalRepoPackages=$(pacman -Sl "$repoName" | cut -d " " -f2 | sort -u | wc -l)
mapfile -t repoPackages < <(pacman -Sl "$repoName" | cut -d " " -f2 | sort -u)
mapfile -t aurPackages < <(yay -Sl aur | cut -d " " -f2 | sort -u)
#Use this diff function to check the differences between arrays
diff(){
	awk 'BEGIN{RS=ORS=" "}
		{NR==FNR?a[$0]++:a[$0]--}
		END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}



echo "$line"
echo "Scanning offical repos for possible duplicate packages in $repoName"
echo "$line"

#Compare the aurmageddon packages to packages in the official repos
for package in $(yay -Sl core community extra | cut -d " " -f2); do
	for repoPkg in "${repoPackages[@]}" ; do
		#Compare the official repo package against a aurmageddon package
		#If these two values match, that means we can remove the package from our repo as it was merged into the main arch repos
		if [ "$package" == "$repoPkg" ]; then
			duplicatePackages+=("$(echo "$repoPkg")")
		fi
	done
done

echo "$line"
echo "Scanning for packages present in $repoName but not in AUR"
echo "$line"

#Check to see if pkg is still in aur
for aurPackage in "${aurPackages[@]}" ; do
	for repoPackage in "${repoPackages[@]}" ; do
		#Compare the official repo package against a aurmageddon package
		if [ "$repoPackage" == "$aurPackage" ]; then
			#Count to 20 and then print a status message
			counter1=$((counter1+1))
			if [[ "$counter1" -gt 25 ]]; then
				counter2=$((counter2+25))
				echo "Checked "$counter2" of "$totalRepoPackages" packages"
				#Reset counter1 to 0 and print a status message again once it hits 25
				counter1=0
			fi
			#validPackages contains all packages that still exist in the AUR
			validPackages+=("$(echo "$repoPackage")")
		fi
	done
done

#Check for differences
packageDiffs=($(diff repoPackages[@] validPackages[@]))

#Print packages that have now been moved to official Arch repos. You can remove these from your repo
echo "$line"
echo "The following packages can be removed from $repoName"
echo "${duplicatePackages[@]}"
echo "$line"
#Print packages that have been removed from the AUR
echo "$line"
echo "The following packages are no longer in the AUR and should be removed"
echo "${packageDiffs[@]}" | tr ' ' '\n' | sort -u
echo "$line"
