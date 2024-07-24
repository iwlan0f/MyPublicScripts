#!/bin/bash


################################################
# README:
#
# Before to run this script
# you need to add the ssh-id
# to the server you want to backup
# all of this to have acces to the 
# server without password like a privileged user.
# server must have a /backup path
#################################################

#  Backup_V2 by iwlan0f

#################################################
# MAIN CONFIG:
service_email='smtpuser@localsmtp.local'
device_user='root'
backup_dir='/backupdisk'
excluded_dirs="/{backup,sys,proc,dev,run,*unifi/db}'*'"
private_ssh_key_path='/srv/keys/backup_key'
admin_mail='admin@mail.es'
##################################################


# If error then tell why and exit
panic_err() { echo $1 ; echo -e "Error message: $1" |mail -s "ERROR! BACKUP FAILED -- $device_name  $(date)" -r $service_email $admin_mail ; exit 2 ;}


# Backup data changed since last backup
incr_backup() {

if [[ ! -d "$backup_dst/incremental_backups"  ]] ; then mkdir $backup_dst/incremental_backups ; fi
for ((i = 5 ; i > 0 ; i--)) ; do mv $backup_dst/incremental_backups/$device_name.backup$i.tgz $backup_dst/incremental_backups/$device_name.backup$(($i + 1)).tgz &>/dev/null ; done

ssh -i $private_ssh_key_path $device_user@$device_ip "tar cpzf - -g /backup/$device_name.snap --exclude=$excluded_dirs $backup_tgt_dir 2>/dev/null" > $backup_dst/incremental_backups/$device_name.backup1.tgz

backup_sz=$(tar tvf $backup_dst/incremental_backups/$device_name.backup1.tgz |awk 'BEGIN {sum=0} {sum+=$3} END {print sum/1024/1024}')
org_sz=$(ssh -i $private_ssh_key_path $device_user@$device_ip "find \"$backup_tgt_dir\" ! -path /sys'*' ! -path /proc'*' ! -path /run'*' ! -path /dev'*' -newermt -24hours -printf \"%s\n\"" | awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024/1024}')

echo -e "Finished $device_name incremental Backup of \"$backup_tgt_dir\" \n\nOrginial fs size:  $org_sz MB. \nbackup size:       $backup_sz MB." |mail -s "New-Backup: $(hostname)-$(date)" -r $service_email $admin_mail
}


# Backup full target system data
full_backup() {

if [[ ! -d "$backup_dst/full_backups"  ]] ; then mkdir $backup_dst/full_backups ; fi
for ((i = 3 ; i > 0 ; i--)) ; do mv $backup_dst/full_backups/$device_name.backup$i.tgz $backup_dst/full_backups/$device_name.backup$(($i + 1)).tgz &>/dev/null ; done

ssh -i $private_ssh_key_path $device_user@$device_ip "rm -rf /backup/$device_name.snap"
ssh -i $private_ssh_key_path $device_user@$device_ip "tar cpzf - -g /backup/$device_name.snap --exclude=$excluded_dirs $backup_tgt_dir 2>/dev/null" > $backup_dst/full_backups/$device_name.backup1.tgz

rm -rf "$backup_dst/incremental_backups"

org_sz=$(ssh -i $private_ssh_key_path $device_user@$device_ip "du -sb --exclude=$excluded_dirs /" |awk 'BEGIN {sum=0} {sum+=$1} END {print sum/1024/1024/1024}')
backup_sz=$(tar tvf $backup_dst/full_backups/$device_name.backup1.tgz 2>/dev/null |awk 'BEGIN {sum=0} {sum+=$3} END {print sum/1024/1024/1024}')

echo -e "Finished $device_name full Backup of \"$backup_tgt_dir\"  \n\nOrginial fs size:  $org_sz GB. \nbackup size:       $backup_sz GB." |mail -s "New-Backup: $(hostname)-$(date)" -r $service_email $admin_mail
}


# Test privileges
[[ $( id -u ) == "0" ]] || panic_err "ERROR! THIS SCIPT NEED TO BE EXECUTED AS ROOT"

# Alert for bad usage
alert='USAGE: ./backup_V2.sh  ip.device.to.backup  --full | --incr  /directory_to_backup'

# Test there are three parameters
if [[ -z $1 || -z $2 || -z $3 ]] ; then echo $alert && exit 1 ; else device_ip=$1 && backup_type=$2 && backup_tgt_dir=$3 ; fi

# Test first parameter is a valid ip
[[ "$device_ip" =~ \  ]] && panic_err "Ip can't contain whitespaces --> \"$device_ip\""
aux='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}0*(1?[0-9]{1,2}|2([   ^`^l   ^`^k0-4][0-9]|5[0-5]))$'
[[ $device_ip =~ $aux  ]] || panic_err "Invalid input ip addr --> \"$device_ip\""

# Test avaliability of target device
device_name=$(ssh -o ConnectTimeout=5 -i $private_ssh_key_path $device_user@$device_ip "hostname")
[[ -z $device_name ]] && panic_err "Device unavaliable! --> \"$device_ip\""

# Test privileges on target device
[[ $( ssh -i $private_ssh_key_path $device_user@$device_ip "id -u" ) == "0" ]] || panic_err "Unprivileged user on target system"

# Create folder to save backups
backup_dst="$backup_dir/$device_name" ; if [[ ! -d "$backup_dst" ]] ; then mkdir $backup_dst ; fi ; if [[ ! -d "$backup_dst" ]] ; then panic_err "Error on create backup folder $backup_dst" ; fi

# Validate second parameter and start backup
if [[ $backup_type == "--incr" ]] ; then incr_backup ; else if [[ $backup_type == "--full" ]] ; then full_backup ; else panic_err "Error on given arguments!" ; fi ; fi

exit 0