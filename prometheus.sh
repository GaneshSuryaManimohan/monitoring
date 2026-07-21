#!/bin/bash

set -e
failure(){
    echo "Error on line $1:$2"
}
trap 'failure "${LINENO}" "$BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIME_STAMP=$(date +%F-%H-%M-%S)
USERID=$(id -u)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log
PROMETHEUS_DIR="/opt/prometheus"



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
if [ -d "$PROMETHEUS_DIR" ]
then
    echo -e "Prometheus already downloaded....$Y SKIPPING $N" | tee -a $LOGFILE
else
    wget https://github.com/prometheus/prometheus/releases/download/v3.13.1/prometheus-3.13.1.linux-amd64.tar.gz &>>$LOGFILE
    VALIDATE $? "Downloading Prometheus"

    tar -xf prometheus.tar.gz &>>$LOGFILE
    VALIDATE $? "Extracting Prometheus"

    mv "prometheus-.linux-amd64" "$PROMETHEUS_DIR" &>>$LOGFILE
    VALIDATE $? "Renaming Prometheus directory"

    rm -f prometheus.tar.gz &>>$LOGFILE
    VALIDATE $? "Cleaning up archive"
fi

cp -f /home/ec2-user/monitoring/prometheus.service /etc/systemd/system/prometheus.service
VALIDATE $? "Copying Prometheus service file"

mkdir -p /opt/prometheus/alert-rules &>>$LOGFILE
VALIDATE $? "Creating alert-rules directory for Prometheus"

cp -f /home/ec2-user/monitoring/*.yml /opt/prometheus/alert-rules &>>$LOGFILE
VALIDATE $? "Copying alert rules files to Prometheus alert-rules directory"

cp -f /home/ec2-user/monitoring/prometheus.yml /opt/prometheus/prometheus.yml &>>$LOGFILE
VALIDATE $? "Copying Prometheus configuration file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reloading systemd"

systemctl start prometheus &>>$LOGFILE
VALIDATE $? "Starting Prometheus service"

systemctl enable prometheus &>>$LOGFILE
VALIDATE $? "Enabling Prometheus service"



