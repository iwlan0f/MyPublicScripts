#!/bin/bash
#
#Script to manage SSH Chroot Jails.
#By iwlan0f.
#
####CONFIG#####
uSeRnAmE="${1}"
jAiLpAtH="/srv/JAILS"
lOgFiLe="${jAiLpAtH}/jailLog.log"
###############


##PANIC ERROR
panic_err(){
local err_file="${BASH_SOURCE[1]}";local err_func="${FUNCNAME[1]}";local err_msg="${1}";local err_code="${2}";local exit_code="${3}"
data_to_log=$(cat<<EOF
ERROR:
    FILE:                    ${err_file}
    FUNCTION:                ${err_func}
    ERRORMSG:                ${err_msg}
    ERRORCODE:               ${err_code}
EOF
)
log_data "${data_to_log}"
exit $exit_code
}

##LOG ANY DATA
log_data(){
data_to_log="###############\n$(date +'%d/%m/%y %T')\n${1}"; echo -e "${data_to_log}\n###############" >> ${lOgFiLe}
}


##Create new user
Create_User() {
local tHiSjAiL="${jAiLpAtH}/${uSeRnAmE}";mkdir "${tHiSjAiL}" 2>/dev/null;mkdir "${tHiSjAiL}/"{home,etc,bin,lib64,lib,usr,dev};mkdir "${tHiSjAiL}/home/${uSeRnAmE}";mkdir "${tHiSjAiL}/lib/x86_64-linux-gnu";mkdir "${tHiSjAiL}/usr/share";

cd "${tHiSjAiL}/dev"; mknod -m 666 null c 1 3;mknod -m 666 tty c 5 0;mknod -m 666 zero c 1 5;mknod -m 666 random c 1 8; cd ${OLDPWD}

useradd -s /bin/bash "${uSeRnAmE}";usermod -p '*' "${uSeRnAmE}"

cp /bin/bash "${tHiSjAiL}/bin/"
cp /lib64/ld-linux-x86-64.so.* "${tHiSjAiL}/lib64/"
cp /lib/x86_64-linux-gnu/libtinfo.so.* "${tHiSjAiL}/lib/x86_64-linux-gnu/"
cp /lib/x86_64-linux-gnu/libdl.so.* "${tHiSjAiL}/lib/"
cp /lib/x86_64-linux-gnu/libc.so.* "${tHiSjAiL}/lib/"
cp /lib64/ld-linux-x86-64.so.* "${tHiSjAiL}/lib64/"


cat <<EOF |base64 -d > "${tHiSjAiL}/home/${uSeRnAmE}/.bashrc"
Y2FzZSAkLSBpbgogICAgKmkqKSA7OwogICAgICAqKSByZXR1cm47Owplc2FjCgpISVNUQ09OVFJP
TD1pZ25vcmVib3RoCgpzaG9wdCAtcyBoaXN0YXBwZW5kCgpISVNUU0laRT0xMDAwCkhJU1RGSUxF
U0laRT0yMDAwCgpzaG9wdCAtcyBjaGVja3dpbnNpemUKCmNhc2UgIlhURVJNIiBpbgogICAgeHRl
cm0tY29sb3J8Ki0yNTZjb2xvcikgY29sb3JfcHJvbXB0PXllczs7CmVzYWMKCgpjYXNlICIkVEVS
TSIgaW4KeHRlcm0qfHJ4dnQqKQogICAgUFMxPSdTVEFSR0FURX4kOiAnCiAgICA7OwoqKQogICAg
OzsKZXNhYwoKaWYgWyAteCAvdXNyL2Jpbi9kaXJjb2xvcnMgXTsgdGhlbgogICAgdGVzdCAtciB+
Ly5kaXJjb2xvcnMgJiYgZXZhbCAiJChkaXJjb2xvcnMgLWIgfi8uZGlyY29sb3JzKSIgfHwgZXZh
bCAiJChkaXJjb2xvcnMgLWIpIgogICAgYWxpYXMgbHM9J2xzIC0tY29sb3I9YXV0bycKZmkKCmV4
cG9ydCBURVJNSU5GTz0vdXNyL3NoYXJlL3Rlcm1pbmZvCmV4cG9ydCBURVJNPXh0ZXJtLWJhc2lj
CgplY2hvIC1lICJcblxuIyMjIyNBdmFsaWFibGUgQ2x1c3RlcnMjIyMjI1xuIgpjYXQgL2V0Yy9o
b3N0cyB8d2hpbGUgcmVhZCBsaW5lIDsgZG8gZWNobyAkbGluZSA7IGRvbmUKZWNobyAtZSAiXG4i
Cg==
EOF

cat <<EOF |base64 -d > "${tHiSjAiL}/home/${uSeRnAmE}/.bash_profile"
IyB+Ly5wcm9maWxlOiBleGVjdXRlZCBieSB0aGUgY29tbWFuZCBpbnRlcnByZXRlciBmb3IgbG9n
aW4gc2hlbGxzLgojIFRoaXMgZmlsZSBpcyBub3QgcmVhZCBieSBiYXNoKDEpLCBpZiB+Ly5iYXNo
X3Byb2ZpbGUgb3Igfi8uYmFzaF9sb2dpbgojIGV4aXN0cy4KIyBzZWUgL3Vzci9zaGFyZS9kb2Mv
YmFzaC9leGFtcGxlcy9zdGFydHVwLWZpbGVzIGZvciBleGFtcGxlcy4KIyB0aGUgZmlsZXMgYXJl
IGxvY2F0ZWQgaW4gdGhlIGJhc2gtZG9jIHBhY2thZ2UuCgojIHRoZSBkZWZhdWx0IHVtYXNrIGlz
IHNldCBpbiAvZXRjL3Byb2ZpbGU7IGZvciBzZXR0aW5nIHRoZSB1bWFzawojIGZvciBzc2ggbG9n
aW5zLCBpbnN0YWxsIGFuZCBjb25maWd1cmUgdGhlIGxpYnBhbS11bWFzayBwYWNrYWdlLgojdW1h
c2sgMDIyCgojIGlmIHJ1bm5pbmcgYmFzaAppZiBbIC1uICIkQkFTSF9WRVJTSU9OIiBdOyB0aGVu
CiAgICAjIGluY2x1ZGUgLmJhc2hyYyBpZiBpdCBleGlzdHMKICAgIGlmIFsgLWYgIiRIT01FLy5i
YXNocmMiIF07IHRoZW4KICAgICAgICAuICIkSE9NRS8uYmFzaHJjIgogICAgZmkKZmkKCiMgc2V0
IFBBVEggc28gaXQgaW5jbHVkZXMgdXNlcidzIHByaXZhdGUgYmluIGlmIGl0IGV4aXN0cwppZiBb
IC1kICIkSE9NRS9iaW4iIF0gOyB0aGVuCiAgICBQQVRIPSIkSE9NRS9iaW46JFBBVEgiCmZpCgoj
IHNldCBQQVRIIHNvIGl0IGluY2x1ZGVzIHVzZXIncyBwcml2YXRlIGJpbiBpZiBpdCBleGlzdHMK
aWYgWyAtZCAiJEhPTUUvLmxvY2FsL2JpbiIgXSA7IHRoZW4KICAgIFBBVEg9IiRIT01FLy5sb2Nh
bC9iaW46JFBBVEgiCmZpCg==
EOF

cp "/bin/"{ssh,scp,clear,nano,ls,cat,sh,mkdir} "${tHiSjAiL}/bin/"

while read line ; do cp "${line}" "${tHiSjAiL}/lib/x86_64-linux-gnu/" 2>/dev/null ; done < <(find / -name libnss*)
while read dep ; do cp "${dep}" "${tHiSjAiL}/lib/x86_64-linux-gnu/" 2>/dev/null ; done < <(ldd "/bin/"{ssh,scp,clear,nano,ls,cat,sh,mkdir} | awk '{print $3}')

cp -r /usr/share/terminfo "${tHiSjAiL}/usr/share/"

cat /etc/passwd |grep "${uSeRnAmE}" > "${tHiSjAiL}/etc/passwd"
cat /etc/group  |grep "${uSeRnAmE}" > "${tHiSjAiL}/etc/group"
cat /etc/shadow |grep "${uSeRnAmE}" > "${tHiSjAiL}/etc/shadow"


cat <<EOF > "${tHiSjAiL}/etc/hosts"
192.168.0.1 youneedtoeditthis
EOF

cat <<EOF > "/etc/ssh/sshd_config.d/${uSeRnAmE}_Jail.conf"
Match User ${uSeRnAmE}
  ChrootDirectory  ${tHiSjAiL}
  AuthorizedKeysFile ${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys
  PubkeyAuthentication yes
  PasswordAuthentication no
  ClientAliveInterval 600
  ClientAliveCountMax 0
  KbdInteractiveAuthentication no
  Banner /etc/issue.net
EOF


mkdir "${tHiSjAiL}/home/${uSeRnAmE}/.ssh"
sudo -u "${uSeRnAmE}" ssh-keygen -t rsa -N '' -f "/tmp/${uSeRnAmE}_key" &> /dev/null

mkdir "${jAiLpAtH}/JAILS_KEYS" 2>/dev/null
mv "/tmp/${uSeRnAmE}_key" "${jAiLpAtH}/JAILS_KEYS/${uSeRnAmE}_key"
mv "/tmp/${uSeRnAmE}_key.pub" "${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys"


chown -R root:root "${tHiSjAiL}"
chmod -R 'u=rwx,g=x,o=x' "${tHiSjAiL}"
chmod -R 'u=rwx,g=rwx,o=rwx' "${tHiSjAiL}/dev"
chmod -R 'u=rwx,g=xr,o=xr' "${tHiSjAiL}/"{lib,lib64,bin,etc,usr}
chown -R "${uSeRnAmE}:${uSeRnAmE}" "${tHiSjAiL}/home/${uSeRnAmE}"
chmod -R 'u=rwx,o=r,g=r' "${tHiSjAiL}/home/${uSeRnAmE}"

chmod 700  "${tHiSjAiL}/home/${uSeRnAmE}/.ssh"
chmod 600  "${tHiSjAiL}/home/${uSeRnAmE}/.ssh/authorized_keys"

chattr +i "${tHiSjAiL}/home/${uSeRnAmE}/"{.bashrc,.bash_profile,.ssh/authorized_keys}

log_data "${uSeRnAmE} - Created succefully"

service sshd restart
}


#DELETE USER
Delete_User() {
tHiSjAiL="${jAiLpAtH}/${uSeRnAmE}"
userdel "${uSeRnAmE}"
chattr -i "${tHiSjAiL}/home/${uSeRnAmE}/"{.bashrc,.bash_profile,.ssh/authorized_keys}

rm -rf "${tHiSjAiL}"
rm -rf "/etc/ssh/sshd_config.d/${uSeRnAmE}_Jail.conf"
rm -rf "${jAiLpAtH}/JAILS_KEYS/${uSeRnAmE}_key"


log_data "${uSeRnAmE} - Deleted succefully"

service sshd reload
}



#Test if root exec this script
[[ $(id -u) == "0"  ]] || panic_err "This Script needs root privileges" "TESTS-001" "2"

#Test for user error
[[ -z "${uSeRnAmE}"  ]] && panic_err "Usage: ./JAIL_CONTROL.sh *Username* add|delete || Ex: ./JAIL_CONTROL.sh rsanchez add" "TESTS-002" "2"

#Test No whitespaces
[[ "${uSeRnAmE}" =~ \  ]] && panic_err "User name contains whitespaces" "TESTS-003" "2"

#Test if jails directory exists
[[ -d "${jAiLpAtH}" ]] ||  mkdir "${jAiLpAtH}" 2>/dev/null ; mkdir "${jAiLpAtH}/JAILS_KEYS" 2>/dev/null
[[ -d "${jAiLpAtH}" ]] ||  panic_err "Impossible to create jails directory on \'${jAiLpAtH}\'" "TESTS-004" "2"

#Start creating new user and verify nonexistent
[[ -z ${2} ]] &&  panic_err "Need one more argument: add | delete" "TESTS-005" "2"

#Call depends on second input
user_aux=$(cat /etc/passwd |grep "${uSeRnAmE}")
if [[ "${2}" == "add" ]] ; then
[[ -z "${user_aux}" ]] && Create_User || panic_err "This user already exist" "TESTS-006" "2"
else
if [[ "${2}" == "delete" ]] ; then
[[ ! -z "${user_aux}" ]] && Delete_User || panic_err "This user dont't exist" "TESTS-007" "2"
else
panic_err "Error on second parameter" "TESTS-008" "2"
fi
fi
