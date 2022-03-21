#!/bin/bash
#
# some centos history settings 
echo "Creating history.sh file to /etc/profile.d/ ......."
cat >/etc/profile.d/history.sh <<EOF
USER_IP=`who -u am i 2>/dev/null | awk '{print $NF}' | sed -e 's/[()]//g'`
if [ -z $USER_IP ]
then
USER_IP=`hostname`
fi

export HISTTIMEFORMAT="[%Y.%m.%d %H:%M:%S] [${USER_IP}-${LOGNAME}] "
export HISTSIZE=10000
EOF

echo "file created , please relogin this session to check history settings."
