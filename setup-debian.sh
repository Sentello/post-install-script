#!/bin/bash
# Spported OS: Debian 10, Ubuntu 20.04
# Post install script ver. 1.0
# INSTRUCTIONS FOR USE:
# 1. Copy this shell script to your /home directory or the /tmp directory.
# 2. Make it executable with the following command: 
#      chmod a+x setup-debian.sh
# 3. Execute the script as a sudo user:
#      sudo ./setup-debian.sh


if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as root" 
   	exit 1
else
	#Update and Upgrade
	echo "Updating and Upgrading"
	apt-get update && apt-get upgrade -y
	
	apt-get install dialog
	cmd=(dialog --separate-output --checklist "Please Select what you want to do:" 22 76 16)
	options=(1 "Set resolv.conf and /etc/hosts" on    # any option can be set to "off"
			2 "Set NTP" on
			3 "Set hostname" on
			4 "Set ssh to permit root and keys only" on
			5 "Install FreeIPA" on
			6 "Set FreeIPA" on
			7 "Reboot server" on)

		choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
		clear
		for choice in $choices
		do
		    case $choice in
			1)
				# Set resolv.conf
				echo "Setting /etc/resolv.conf"
				echo "domain tux.oict.cz" > /etc/resolv.conf
				echo "search tux.oict.cz" >> /etc/resolv.conf
				echo "nameserver 10.130.101.8" >> /etc/resolv.conf
				echo "nameserver 10.130.101.9" >> /etc/resolv.conf
				
				# Edit /etc/hosts
				echo "# FreeIPA Servers" >> /etc/hosts
				echo "10.130.101.8 ipa.tux.oict.cz ipa" >> /etc/hosts
				echo "10.130.101.9 ipa2.tux.oict.cz ipa2" >> /etc/hosts
				;;
			2)
				# Set NTP
				cp /etc/ntp.conf /etc/ntp.conf.bak
				> /etc/ntp.conf
				sh -c 'echo "# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

				driftfile /var/lib/ntp/ntp.drift
				leapfile /usr/share/zoneinfo/leap-seconds.list
				statistics loopstats peerstats clockstats
				filegen loopstats file loopstats type day enable
				filegen peerstats file peerstats type day enable
				filegen clockstats file clockstats type day enable
				server ntp1.oict.cz iburst
				server ntp2.oict.cz iburst
				restrict -4 default kod notrap nomodify nopeer noquery limited
				restrict -6 default kod notrap nomodify nopeer noquery limited
				restrict 127.0.0.1
				restrict ::1
				restrict source notrap nomodify noquery" >> /etc/ntp.conf'
				;;
			3)
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
				;;
    		4)	
				# Permit Root login:
				sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
				
				# Only SSH keys:
				sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
				systemctl reload ssh
				echo "Finished with setup"
				;;
				
			5)
				# Install FreeIPA
				echo "
				######################################################################################################
						Do you want to install FreeIPA? If so type y / If you dont want to install enter n
				######################################################################################################
				"
				read $ipa

				if [[ $ipa -eq "y" ]] || [[ $ipa -eq "yes" ]]; then
					apt -y update && apt -y upgrade && apt -y install freeipa-client && \
					apt -y autoremove && apt -y clean 
				 
				echo "
				#####################################################################################################    
											  FreeIPA has been installed
				#####################################################################################################
				"
				echo "FreeIPA version:"
					ipa --version

				else 
					echo "FreeIPA was not installed!!!"
				 
				fi
				;;

			6)
				# Set FreeIPA
				ipa-client-install --mkhomedir --no-ntp
				;;
			7)
				# Reboot the system
				read -s -n 1 -p "Press any key to reboot!"
				echo ""
				echo "Okey, Rebooting"
				reboot now
				;;
	    esac
	done
fi
