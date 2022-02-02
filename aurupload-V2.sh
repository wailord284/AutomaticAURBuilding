#!/bin/bash
###Do not put a trailing / for the build and package directory###
#Repository Name
repoName="aurmageddon"
#This is the path to where packages will be built
repoBuildDirectory="/mnt/aurbuild/AurmageddonBuild"
#This is the path where the final package and database will be placed
#Within this directory, create a "packages" and "database" folder
repoPackageDirectory="/mnt/aurbuild/AurmageddonRepo"
#This is the username@domain used when connecting over SSH for rsync
#To automatically connect without a password, setup SSH keys and create a config line for your domain with the identity file
remoteRepoLogin="alex@wailord284.club"
#This is the remote path rsync should place the repo/package files in
remoteRepoPath="/var/www/wailord284.club/public/repo/aurmageddon/x86_64/"


cd "$repoPackageDirectory" || echo "Could not find $repoPackageDirectory"
#Remove the old database files
rm -r "$repoPackageDirectory"/database/*
printf "\e]2;Generating database files...\a"
#Generate the repo database with all *.pkg.tar.zst files in the /packages/ directory
repo-add -n -R "$repoPackageDirectory"/database/"$repoName".db.tar.gz "$repoPackageDirectory"/packages/*.pkg.tar.zst

cd "$repoPackageDirectory" || echo "Could not find $repoPackageDirectory"
printf "\e]2;Syncing repository and packages with remote server...\a"
#Sync packages and database to remote server with rsync. If possible, install rsync on the remote server as well
rsync --delete-delay -Pavhe ssh "packages/" "$remoteRepoLogin":"$remoteRepoPath"
sleep 5s
rsync --inplace -Pavhe ssh "database/" "$remoteRepoLogin":"$remoteRepoPath"
printf "\033]\007"
