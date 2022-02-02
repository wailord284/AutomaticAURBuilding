# An automatic system for build your own AUR software repository on Arch
This project contains a small collection of scripts to manage and create your own Arch software repository. All compiled packages will end up uploaded to a remote server allowing others to download your packages.

I use this script to build AUR packages for my [aurmageddon](https://wailord284.club) repository. Append the following to your pacman.conf if you wish to utilize it.

```
[aurmageddon]
Server = http://wailord284.club/repo/$repo/$arch
SigLevel = Never 
```

# How it works
This AUR builder depends on the [aurutils](https://aur.archlinux.org/packages/aurutils/) utility to download packages. To tell the script what packages you want to build, you can create a text file with names of software. This current configuration has a aurpackages.txt and aurgitpackages.txt that will be processed.

The end result will copy all package files to a user specified location, and then use rsync over SSH to move the files to a remote server. It is recommended you install rsync and configure SSH keys or some other automatic login to your remote server.

# How to use
I personally run this within an Arch Linux systemd-nspawn container. However, running it on any system with Arch will be totally fine.
- After following the configuration below, you can run the script
    * The included build.sh and cronbuild.sh files may help in automation
    
```
./aurbuild-V4.sh
./aurupload-V2.sh
```

## Configuration - The two main files
- Find the following variables in aurbuild-V4.sh
    * repoBuildDirectory - Change this to a location where packages will be built
    * repoPackageDirectory - Change this to a location where final packages will be stored
    * aurPackages - Change this to the list containing your desired packages
    * aurGitPackages - Change this to the list containing your desired git packages (this is optional)

- Find the following variables in aurupload-V2.sh
    * repoName - Change to your repository name
    * repoBuildDirectory - Change this to a location where packages will be built
    * repoPackageDirectory - Change this to a location where final packages will be stored
    * remoteRepoLogin - Change this to your username@ipaddress for SSH
    * remoteRepoPath - Change this to the remote location on your server where files/packages will end up

## Configuration - Extra utilities (Optional)
- The remaining scripts are all optional but may be useful
- aursort.sh - A script to sort and remove duplicate packages from your package lists
    * aurPackages - Change this to the list containing your desired packages
    * aurGitPackages - Change this to the list containing your desired git packages (this is optional)
    * repoPackageDirectory - Change this to a location where final packages will be store
- aurremove.sh - A script to remove all traces of a package from the package, build and package lists
    * repoBuildDirectory - Change this to a location where packages will be built
    * repoPackageDirectory - Change this to a location where final packages will be stored
    * aurPackages - Change this to the list containing your desired packages
    * aurGitPackages - Change this to the list containing your desired git packages (this is optional)
- pkgcheck.sh - A script to check if packages in the package list no longer exist in the AUR or were moved to the main repos. Please note this also requires [yay](https://aur.archlinux.org/packages/yay/)
    * pkgOutput - Change this to an output location
    * aurpkgOutput - Change this to an output location
    * repoName - Change to the name of YOUR repository to check against

# Config Examples

## aurbuild-V4.sh
![aurbuild](/images/aurbuild.png)

## aurupload-V2.sh
![aurupload](/images/aurupload.png)

## aurremove.sh
![aurremove](/images/aurremove.png)

## aursort.sh
![aursort](/images/aursort.png)

## pkgcheck.sh
![pkgcheck](/images/pkgcheck.png)
