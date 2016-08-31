#!/bin/bash
function hdd_health() {
for sdX in `lsblk -l --output NAME,TYPE,ROTA | egrep 'disk.*1' | awk {'print $1'}`;
do
	declare -a health=(`/usr/sbin/smartctl -a /dev/$sdX | awk '/Reallocated_Sector_Ct/ || /Seek_Error_Rate/ { print $2" "$NF }'`)
	declare -a info=(`/usr/sbin/smartctl -a /dev/$sdX | egrep -i "device model|serial number" | awk '{print $NF}'`)
			hdd=" 'name':'$sdX',
			'model':'${info[0]}',
			'serial':'${info[1]}',
			'${health[0]}':'${health[1]}',
			'${health[2]}':'${health[3]}',
			'partition':["
	echo {$hdd

	for part in `lsblk -l /dev/$sdX --output NAME,TYPE,ROTA | grep part | awk {'print $1'}`
	do
		part_type=`lsblk -l /dev/$sdX | grep $part | awk {'print $6'}`
		part_space=`lsblk -l /dev/$sdX | grep $part | awk {'print $4'}`
		part_mount=`lsblk -l /dev/$sdX | grep $part| awk {'print tolower ($7)'} | sed 's/\[//;s/\]//'`
		part_used=`df -h | grep $part | awk {'print $3'}`
		part_ava=`df -h | grep $part | awk {'print $4'}`

		usage=" 'name':'$part',
		'type':'$part_type',
		'space':'$part_space',
		'mount':'$part_mount',
		'used':'$part_used',
		'avail':'$part_ava'"
		echo -n {$usage},
	done | sed 's/,$//'
printf "]},"
done | sed 's/},$//'
}

function ssd_health() {
for sdX in `lsblk -l --output NAME,TYPE,ROTA | egrep 'disk.*0' | awk {'print $1'}`;
do
	declare -a health=(`/usr/sbin/smartctl -a /dev/$sdX | awk '/Media_Wearout_Indicator/ || /Remaining_Lifetime_Perc/ || /Wear_Leveling_Count/ { print $2" "$4 }'`)
	declare -a info=(`/usr/sbin/smartctl -a /dev/$sdX | egrep -i "device model|serial number" | awk '{print $NF}'`)
			hdd=" 'name':'$sdX',
			'model':'${info[0]}',
			'serial':'${info[1]}',
			'${health[0]}':'${health[1]}',
			'${health[2]}':'${health[3]}',
			'partition':["
	echo {$hdd

	for part in `lsblk -l /dev/$sdX --output NAME,TYPE,ROTA | grep part | awk {'print $1'}`
	do
		part_type=`lsblk -l /dev/$sdX | grep $part | awk {'print $6'}`
		part_space=`lsblk -l /dev/$sdX | grep $part | awk {'print $4'}`
		part_mount=`lsblk -l /dev/$sdX | grep $part| awk {'print tolower ($7)'} | sed 's/\[//;s/\]//'`
		part_used=`df -h | grep $part | awk {'print $3'}`
		part_ava=`df -h | grep $part | awk {'print $4'}`

		usage=" 'name':'$part',
		'type':'$part_type',
		'space':'$part_space',
		'mount':'$part_mount',
		'used':'$part_used',
		'avail':'$part_ava'"
		echo -n {$usage},
	done | sed 's/,$//'
printf "]},"	
done 
}

function cpu() {
core=`lscpu | grep 'CPU(s):'| head -n 1 | sed 's/CPU(s)/Jumlah-core/'`
speed=`lscpu | grep 'MHz'| head -n 1  | sed 's/CPU MHz/Clock-CPU-MHz/'`
model=`cat /proc/cpuinfo | grep 'model name' | head -n 1`
temp=`sensors | grep 'Core 0' | awk '{print $1,$3}' | sed 's/Core/Temp :/'`
usage=`top -bn1 | grep "Cpu(s)" | awk '{print $1,$2}' | sed 's/Cpu(s)/Usage/;s/\,//g'`

printf "\"cpu\":\n"
printf "{\"$core\",\"$speed\",\"$model\",\"$temp\",\"$usage\"}," | sed -e 's/\s\+//g;s/:/\":\"/g'
}


#Check Dependencies
if [ -z /usr/bin/sensors ]; then
	yum -y install lm_sensors
	yes | sensors-detect
	echo "sensors install finish"
fi

function mem(){
free -m | sed -n 2p | awk '{print "free: " $4" MB"}'
free -m | sed -n 2p | awk '{print "used: " $3" MB"}'
free -m | sed -n 2p | awk '{print "total: " $2" MB"}'
dmidecode -t 17 | egrep "Size:|Type:" | sed -e 's/^[ \t]*//' | head -n -2
}

printf {\"disk\":[
ssd_health | sed -e 's/ //g' -e s/\'/\"/g;
hdd_health | sed -e 's/ //g' -e s/\'/\"/g; 
printf }],

cpu

printf \"memory\"\:
printf {
mem | sed -e 's/\s\+//g;s/:/\":\"/g'| sed -e "s/.*/\"&\"/;s/$/\,/g" | sed ':a;N;$!ba;s/\n//g;s/,$//'
printf }
printf }
