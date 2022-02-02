#!/bin/bash
#Colors
green=$(tput setaf 2)
reset=$(tput sgr 0)
red=$(tput setaf 1)
#Set output file to store duplicated packages
pkgOutput="/home/alex/pkgdupe.txt"
aurpkgOutput="/home/alex/aurpkgdupe.txt"
#Get a list of all packages in the aurmageddon repo
declare -a repoPackages aurPackages archPackages
mapfile -t repoPackages < <(pacman -Sl aurmageddon | cut -d " " -f2 | sort -u)
mapfile -t aurPackages < <(yay -Sl aur | cut -d " " -f2 | sort -u)
mapfile -t mainRepoPackages < <(pacman -Sl core community extra | cut -d " " -f2)

echo "Scanning offical repos for possible duplicate packages in aurmageddon"
#Compare the aurmageddon packages to packages in the official repos
for package in $(yay -Sl core community extra | cut -d " " -f2); do
	for repoPkg in "${repoPackages[@]}" ; do
		#Compare the official repo package against a aurmageddon package
		if [ "$package" == "$repoPkg" ]; then
			echo "$repoPkg" >> "$pkgOutput"
		fi
	done
done

#echo "Scanning for packages present in Aurmageddon but not in AUR"
#Check to see if pkg is still in aur
for aurpackage in "${aurPackages[@]}" ; do
	for repoPkg in "${repoPackages[@]}" ; do
		#Compare the official repo package against a aurmageddon package
		if [ "$repoPkg" == "$aurpackage" ]; then
			echo "$green$repoPkg$reset exists in AUR"
			validPkg+=("$(echo "$repoPkg")")
		fi
	done
done
#Print differences
diff(){
  awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
}

Array3=($(diff repoPackages[@] validPkg[@]))
echo ${Array3[@]} | tr ' ' '\n' | sort -u
