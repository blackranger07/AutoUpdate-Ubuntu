#!/usr/bin/bash

# Automated System Update Installer

if [ ${EUID} -ne 0 ]; then
	echo "You must be root to run this installer."
	exit 1
fi

automationsetup () {

FILEDIR="/etc/systemd/system"

echo "Creating files Ubuntu-Packages-Update.service and Ubuntu-Packages-Update.timer in /etc/systemd/system"
sleep 2
if [ ! -e ${FILEDIR}/Ubuntu-Packages-Update.service ]; then
	cat > ${FILEDIR}/Ubuntu-Packages-Update.service <<EOF
	[Unit]
	Description=Updates Ubuntu Packages
	Wants=Ubuntu-Packages-Update.timer

	[Service]
	Type=oneshot
	ExecStart=sudo apt update -y

	[Install]
	WantedBy=multi-user.target
EOF

if [ $? == 0 ]; then
	if [ ! -e ${FILEDIR}/Ubuntu-Packages-Update.timer ]; then
		 cat > ${FILEDIR}/Ubuntu-Packages-Update.timer <<EOF
		[Unit]
		Description=Calls the Ubuntu-Packages-Update.service Weekly on Monday at 2am.
		Requires=Ubuntu-Packages-Update.service

		[Timer]
		Unit=Ubuntu-Packages-Update.service
		OnCalendar=Mon *-*-* 02:00:00 

		[Install]
		WantedBy=timers.target
EOF

	fi
else
	echo "There was an issue creating the service file."
	exit 1
fi

if [ $? == 0 ]; then
	#Modify permissions for root to have Full privileges.
	chmod 764 ${FILEDIR}/Ubuntu-Packages-Update.*
	if [ $? == 0 ]; then
		echo "File permissions changed for Ubuntu-Packages-Update.service and Ubuntu-Packages-Update.timer"
		echo "Enabling the timer."
		systemctl enable Ubuntu-Packages-Update.timer
		if [ $? == 0 ]; then
			echo "Reloading daemon."
			systemctl daemon-reload
			if [ $? == 0 ]; then
				echo "Verify start date on screen."
				sleep 2
				systemctl status Ubuntu-Packages-Update.timer
				echo "Done!"
			fi
		fi
	fi

fi

}

read -p "Continue with running Automated System Update Installer? (y/N): " CHOICE

if [ ${CHOICE} == "y" ] || [ ${CHOICE} == "Y" ]; then
	echo "Automated System Update starting configuration..."
	automationsetup
else
	echo "Installation aborted."
	exit 1
fi