#!/bin/bash
Help()
{
   # Display Help
   echo "Script will execute git operations using a specifid key"
   echo
   echo "Usage: git_key.sh key operaton"
   echo
}

if [ "$#" -ne 2 ]; then
	Help
	exit
else
	GIT_SSH_COMMAND="ssh -i ${1}" git ${2}
fi
