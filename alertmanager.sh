#!/bin/bash

set -e
failure(){
    echo "Error on line $1:$2"
}
trap 'failure "${LINENO}" "$BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
TIME_STAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log
USERID=$(id -u)
ALERTMANAGER_DIR="/opt/alertmanager"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2....$R FAILURE $N"
        exit 1
    else
        echo -e "$2....$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script as super user"
    exit 1
else
    echo "Running the script as super user"
fi

cd /opt &>>$LOGFILE
VALIDATE $? "Changing directory to /opt"

if [ -d "$ALERTMANAGER_DIR" ]
then
    echo -e "Alertmanager already downloaded....$Y SKIPPING $N" | tee -a $LOGFILE
else
    wget https://github.com/prometheus/alertmanager/releases/download/v0.33.1/alertmanager-0.33.1.linux-amd64.tar.gz &>>$LOGFILE
    VALIDATE $? "Downloading Alertmanager"

    tar -xzf alertmanager-0.33.1.linux-amd64.tar.gz
    VALIDATE $? "Extracting Alertmanager"

    mv "alertmanager-0.33.1.linux-amd64" "$ALERTMANAGER_DIR" &>>$LOGFILE
    VALIDATE $? "Renaming Alertmanager directory"
fi

# Idempotent copy: only copy (and reload) if the file actually changed
if ! cmp -s /home/ec2-user/monitoring/alertmanager.service /etc/systemd/system/alertmanager.service 2>/dev/null
then
    cp -f /home/ec2-user/monitoring/alertmanager.service /etc/systemd/system/alertmanager.service &>>$LOGFILE
    VALIDATE $? "Copying Alertmanager service file"

    systemctl daemon-reload &>>$LOGFILE
    VALIDATE $? "Daemon reloading systemd"
else
    echo -e "Alertmanager service file unchanged....$Y SKIPPING $N" | tee -a $LOGFILE
fi

# Idempotent start
if systemctl is-active --quiet alertmanager
then
    echo -e "Alertmanager already running....$Y SKIPPING $N" | tee -a $LOGFILE
else
    systemctl start alertmanager &>>$LOGFILE
    VALIDATE $? "Starting Alertmanager service"
fi

# Idempotent enable
if systemctl is-enabled --quiet alertmanager 2>/dev/null
then
    echo -e "Alertmanager already enabled....$Y SKIPPING $N" | tee -a $LOGFILE
else
    systemctl enable alertmanager &>>$LOGFILE
    VALIDATE $? "Enabling Alertmanager service"
fi