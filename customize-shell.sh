#!/bin/bash

######
## runs ansible to install a bunch of devops tools, then customizes the terminal/shell

##  REQUIRES ansible/python/python-xml to be preinstalled
##  NOPASSWD sudo access or prexisting sudo session (sudo whoami or similar)

##  SECURITY notes: script does not currently have a way to validate the package/installers for package control and oh-my-zsh. the script will download them for you,
##  display them, and prompt for confirmation before installing.
######

set -u  #throw error on unset variables as safety check

ANSIBLE_CMD="ansible-playbook --connection=local --inventory=127.0.0.1, --limit=127.0.0.1 --check ansible/devops-workstations.yml -e 'ansible_python_interpreter=/usr/bin/python3'"
SUBLIME_PATH="$HOME/.config/sublime-text-3" 
SUBLIME_PLUGIN_PATH="$SUBLIME_PATH/Installed Packages"

PACKAGE_CONTROL_URL="https://packagecontrol.io/Package%20Control.sublime-package"
PACKAGE_CONTROL_PATH="$SUBLIME_PLUGIN_PATH/Package Control.sublime-package"

OHMYZSH_PATH="$HOME/.oh-my-zsh"
OHMYZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

AWSCLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

install_ohmyzsh(){
	echo "oh-my-zsh does not appear to be installed, downloading installer"
	curl -Lo ohmyzsh-installer.sh "$OHMYZSH_URL"
	less ohmyzsh-installer.sh
	echo "Do you wish to continue with the oh-my-zsh install?"
	select yn in "Yes" "No"; do
		case $yn in
	   		Yes ) chmod u+x ohmyzsh-installer.sh; ./ohmyzsh-installer.sh;  break;;
	   		No ) exit;;
		esac
	done
}

install_aws_cli(){
	if [ ! -f "awscliv2.zip" ]
	then
		curl -o "awscliv2.zip" "$AWSCLI_URL"
	fi

	if [ ! -f "awscliv2.sig" ]
	then
		curl -o awscliv2.sig "$AWSCLI_URL.sig"
	fi

	gpg --import aws-cli.pub
	gpg --verify awscliv2.sig awscliv2.zip

	sig_verification=$?
	if [ $sig_verification -eq 0 ]
	then
		echo "AWS cli package sig verification OK, installing..."
	else
		echo "AWS cli package sig verification failed, skipping."
	fi

}

is_ansible_playbook_installed(){
	if [ -x "$(command -v ansible-playbook)" ]
	then
		return 1
	else
		return 0
	fi
}

is_sublime_text_installed (){
	if [ -d "$SUBLIME_PATH" ]
	then
		return 1
	else
		return 0
	fi
}

is_package_control_installed (){
	if [ -f "$PACKAGE_CONTROL_PATH" ]
	then
		return 1
	else
		return 0
	fi	
}

is_ansible_playbook_installed
status=$?
if [ $status -eq 1 ]
then
	echo "ansible-playbook is installed, running playbook."
	$ANSIBLE_CMD
else
	echo "ansible-playbook isn't installed"
fi

is_sublime_text_installed
status=$?
if [ $status -eq 1 ]
then
	echo "Sublime Text 3 Installed"
	is_package_control_installed
	status=$?

	if [ $status -eq 1 ]
	then
		echo "Package Control plugin already installed, skipping..."
	else
		echo "Package Control plugin not installed, installing..."
		wget -O "$SUBLIME_PLUGIN_PATH/Package Control.sublime-package" "$PACKAGE_CONTROL_URL"
	fi
else
	echo "Submlime Text 3 not installed, please check to make sure it's properly installed and that SUBLIME_PLUGIN_PATH is configured properly "
fi



# setup zsh as default shell and install oh-my-zsh if it's not already installed

if [ -x "$(command -v zsh)" ]
then
	echo "ZSH is installed"
	if [ "$SHELL" == "/usr/bin/zsh" ]
	then
		echo "current shell is already zsh, skipping..."

	else
		echo "current shell is not zsh ($SHELL), attempting to set as default..."
		chsh -s /usr/bin/zsh
	fi

	if [ -d "$OHMYZSH_PATH" ]
		then
			echo "oh-my-zsh appears to be installed, skipping..."
		else
			echo "Installing oh-my-zsh..."
			install_ohmyzsh
			echo "You may need to log out and back in to load zsh as your default shell"
	fi
else
	echo "ZSH is not installed, current shell is $SHELL"
fi
 
install_aws_cli


#TODO: manual steps to be automated
#setup prompt() in .zshrc
#set oh-my-zsh theme to agnoster
#setup solarized theme in terminal