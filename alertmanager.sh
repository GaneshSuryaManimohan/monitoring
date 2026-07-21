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

wget https://github.com/prometheus/alertmanager/releases/download/v0.33.1/alertmanager-0.33.1.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Downloading Alertmanager"

mv /opt/alertmanager-0.33.1.linux-amd64 alertmanager &>>$LOGFILE
VALIDATE $? "Renaming Alertmanager directory"

cp -f /home/ec2-user/monitoring/alertmanager.service /etc/systemd/system/alertmanager.service  &>>$LOGFILE
VALIDATE $? "Copying Alertmanager service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reloading systemd"

systemctl start alertmanager &>>$LOGFILE
VALIDATE $? "Starting Alertmanager service"

systemctl enable alertmanager &>>$LOGFILE
VALIDATE $? "Enabling Alertmanager service"