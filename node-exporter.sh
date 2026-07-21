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

if [ $USERID -ne 0 ]
then
    echo "Please run this script as super user"
    exit 1
else
    echo "Running the script as super user"
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2....$R FAILURE $N"
        exit 1
    else
        echo -e "$2....$G SUCCESS $N"
    fi
}


cd /opt &>>$LOGFILE 
VALIDATE $? "Changing directory to /opt"

wget https://github.com/prometheus/node_exporter/releases/download/v1.12.1/node_exporter-1.12.1.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Downloading Prometheus Node Exporter"

tar -xf node_exporter-1.12.1.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Extracting Prometheus Node Exporter"

mv /opt/node_exporter-1.12.1.linux-amd64 node_exporter &>>$LOGFILE
VALIDATE $? "Renaming Node Exporter directory"

cp -f /home/ec2-user/monitoring/node_exporter.service /etc/systemd/system/node_exporter.service &>>$LOGFILE
VALIDATE $? "Copying Node Exporter service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reloading systemd"

systemctl start node_exporter &>>$LOGFILE
VALIDATE $? "Starting Node Exporter service"

systemctl enable node_exporter &>>$LOGFILE
VALIDATE $? "Enabling Node Exporter service"

