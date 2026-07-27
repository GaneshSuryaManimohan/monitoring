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

NODE_EXPORTER_VERSION="1.12.1"
NODE_EXPORTER_DIR="/opt/node_exporter"

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

# Idempotent download+extract: skip if already installed
if [ -d "$NODE_EXPORTER_DIR" ]
then
    echo -e "Node Exporter already downloaded....$Y SKIPPING $N" | tee -a $LOGFILE
else
    wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz -O node_exporter.tar.gz &>>$LOGFILE
    VALIDATE $? "Downloading Prometheus Node Exporter"

    tar -xf node_exporter.tar.gz &>>$LOGFILE
    VALIDATE $? "Extracting Prometheus Node Exporter"

    mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" "$NODE_EXPORTER_DIR" &>>$LOGFILE
    VALIDATE $? "Renaming Node Exporter directory"

    rm -f node_exporter.tar.gz &>>$LOGFILE
    VALIDATE $? "Cleaning up archive"
fi

# Idempotent service file copy: only reload if it actually changed
if ! cmp -s /home/ec2-user/monitoring/node_exporter.service /etc/systemd/system/node_exporter.service 2>/dev/null
then
    cp -f /home/ec2-user/monitoring/node_exporter.service /etc/systemd/system/node_exporter.service &>>$LOGFILE
    VALIDATE $? "Copying Node Exporter service file"

    systemctl daemon-reload &>>$LOGFILE
    VALIDATE $? "Daemon reloading systemd"
else
    echo -e "Node Exporter service file unchanged....$Y SKIPPING $N" | tee -a $LOGFILE
fi

# Idempotent start
if systemctl is-active --quiet node_exporter
then
    echo -e "Node Exporter already running....$Y SKIPPING $N" | tee -a $LOGFILE
else
    systemctl start node_exporter &>>$LOGFILE
    VALIDATE $? "Starting Node Exporter service"
fi

# Idempotent enable
if systemctl is-enabled --quiet node_exporter 2>/dev/null
then
    echo -e "Node Exporter already enabled....$Y SKIPPING $N" | tee -a $LOGFILE
else
    systemctl enable node_exporter &>>$LOGFILE
    VALIDATE $? "Enabling Node Exporter service"
fi