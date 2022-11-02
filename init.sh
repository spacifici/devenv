#!/bin/bash

declare -r USER="`cat /root/.userinfo`"
declare -r OLD_HOME="/home/${USER}"
declare -r NEW_HOME="/data/home"

# Create the data home directory if needed
mkdir -p "${NEW_HOME}"
chown "${USER}:${USER}" "${NEW_HOME}"

# Sync the old home to the new directory if needed
rsync -au "/home/${USER}/" "${NEW_HOME}"

# Adjust the symlinks to be relative to the new home directory
find "${NEW_HOME}" -type l -not -iregex ".*oh-my-zsh.*" | while read link; do
	link_path="`readlink "${link}"`"
	new_path="`echo "${link_path}"|sed "s|${OLD_HOME}|${NEW_HOME}|g"`"
	ln -sfv "${new_path}" "${link}"
done

# Make the user use the new source folder
usermod -d "${NEW_HOME}" "${USER}"

# Start the ssh server
/usr/sbin/sshd -D -e
