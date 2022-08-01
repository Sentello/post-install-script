#!/bin/bash
# Spported OS: Debian 10/11, Ubuntu 20.04, Ubuntu 22.04, AlmaLinux 9.0
# Post install script ver. 1.0
# INSTRUCTIONS FOR USE:
# 1. Copy this shell script to your /home directory or the /tmp directory.
# 2. Make it executable with the following command: 
#      chmod a+x setup-linux-mhmp.sh
# 3. Execute the script as a sudo user:
#      sudo ./setup-linux-mhmp.sh


if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as root" 
   	exit 1
else
	#Update and Upgrade
	echo "Updating and Upgrading"
	apt-get update && apt-get upgrade -y &&	apt-get install open-vm-tools -y
	dnf update && dnf upgrade -y &&	dnf install open-vm-tools -y
	apt-get install dialog -y
	dnf install dialog -y
	cmd=(dialog --separate-output --checklist "Please, select what do you want to do:" 22 76 16)
	options=(1 "Set hostname" off # any option can be set to "off"
			2 "Set hostname in zabbix_agentd.conf" on
			3 "Create new sudo user" on
			9 "Reboot server" off)

		choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
		clear
		for choice in $choices
		do
		    case $choice in
			1)
			 # Set hostname
			 curhostname=$(cat /etc/hostname)
				
			 # Display current hostname
			 echo "Current hostname: '$curhostname'"
				
			 # Set $newhostname as new hostname 
			 echo "Enter new hostname: "
			 read newhostname
				
			 # Change the hostname in /etc/hostname, /etc/hosts files and hostnamectl
			 sed -i "s/$curhostname/$newhostname/g" /etc/hostname
			 sed -i "s/$curhostname/$newhostname/g" /etc/hosts
			 hostnamectl set-hostname $newhostname
				
			 # Display new hostname
			 echo "New hostname: $newhostname"
			 echo " "
			 ;;
			2)
			  # Display current hostname
			  curhostname=$(cat /etc/hostname)
			  echo "Current hostname: '$curhostname'"
			  sed -i "s/# Hostname=/Hostname=$curhostname/" /etc/zabbix/zabbix_agentd.conf
			  ;;
		        3)
                          # Parameter is user name
                          echo "Enter new user name: "
                          read USER_NAME
                

                          # The rest of the parameters are for accout comments
                          shift
                          echo "Enter account comments:  "
			  read COMMENT
                
                          # Read SSH pub key
                          shift
                          echo "Enter user account authorized SSH key: "
                          read SSHKEY
                          # Create the user wtih teh password.
                          useradd -c "${COMMENT}" -m ${USER_NAME} -s /bin/bash &> /dev/null
                          # Check to see if the useradd command succeeded
                
                          if [[ "${?}" -ne 0 ]]
                             then
                                 echo 'ERROR: The account could not be created.' >&2
                             exit 1
                          fi

                         # Set the password
                         PASSWORD=$(date +%s%N | base64 )
                         # echo ${PASSWORD} | passwd --stdin ${USER_NAME} &> /dev/null
                         echo -e "${PASSWORD}\n${PASSWORD}" | passwd ${USER_NAME} &> /dev/null
                
                         # Check to see if the password command succeeded
                         if [[ "${?}" -ne 0 ]]
                            then
                                echo 'ERROR: The password could not be set.' >&2
                            exit 1
                         fi

                         # Force password change on first login
                         passwd -e ${USER_NAME} &> /dev/null
                
                         # Add user to sudo 
                         usermod -aG sudo ${USER_NAME}
			 sudo gpasswd -a ${USER_NAME} wheel
                
                         # SSH keys folder
                         mkdir /home/${USER_NAME}/.ssh
                         touch /home/${USER_NAME}/.ssh/authorized_keys
                         chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.ssh
                         chmod 700 /home/${USER_NAME}/.ssh
                         echo ${SSHKEY} > /home/${USER_NAME}/.ssh/authorized_keys
                         chmod 600 /home/${USER_NAME}/.ssh/authorized_keys
			 echo " "
			 
                         # Display the username, password, and the host where the user was created
                         echo 'Yaaay, User was created'
                         echo 'username: '
                         echo "${USER_NAME}"
                         echo " "
                         echo 'password: '
                         echo "${PASSWORD}"
                         echo " "
                         curhostname=$(cat /etc/hostname)
                         echo 'hostname: '
                         echo "${curhostname}"
                         ;;
		        9)
			 # Reboot the system
			 read -s -n 1 -p "Press any key to reboot!"
			 echo " "
			 echo "Okey, rebooting"
			 sleep 5
			 reboot now
			 ;;
	    esac
	done
fi
