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

PROMETHEUS_VERSION="3.13.1"
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
    wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz -O prometheus.tar.gz &>>$LOGFILE
    VALIDATE $? "Downloading Prometheus"

    tar -xf prometheus.tar.gz &>>$LOGFILE
    VALIDATE $? "Extracting Prometheus"

    mv "prometheus-${PROMETHEUS_VERSION}.linux-amd64" "$PROMETHEUS_DIR" &>>$LOGFILE
    VALIDATE $? "Renaming Prometheus directory"

    rm -f prometheus.tar.gz &>>$LOGFILE
    VALIDATE $? "Cleaning up archive"
fi

# Track whether anything changed, so we only reload/restart when needed
NEEDS_RESTART=0

# Idempotent service file copy
if ! cmp -s /home/ec2-user/monitoring/prometheus.service /etc/systemd/system/prometheus.service 2>/dev/null
then
    cp -f /home/ec2-user/monitoring/prometheus.service /etc/systemd/system/prometheus.service &>>$LOGFILE
    VALIDATE $? "Copying Prometheus service file"
    NEEDS_RESTART=1
else
    echo -e "Prometheus service file unchanged....$Y SKIPPING $N" | tee -a $LOGFILE
fi

mkdir -p /opt/prometheus/alert-rules &>>$LOGFILE
VALIDATE $? "Creating alert-rules directory for Prometheus"

# Sync alert rules; -u only copies newer/changed files, and we detect
# whether anything actually changed for the restart decision
CHANGED_RULES=$(cp -uv /home/ec2-user/monitoring/*.yml /opt/prometheus/alert-rules/ 2>>$LOGFILE | wc -l)
VALIDATE $? "Copying alert rules files to Prometheus alert-rules directory"
if [ "$CHANGED_RULES" -gt 0 ]
then
    NEEDS_RESTART=1
fi

# Idempotent config copy
if ! cmp -s /home/ec2-user/monitoring/prometheus.yml /opt/prometheus/prometheus.yml 2>/dev/null
then
    cp -f /home/ec2-user/monitoring/prometheus.yml /opt/prometheus/prometheus.yml &>>$LOGFILE
    VALIDATE $? "Copying Prometheus configuration file"
    NEEDS_RESTART=1
else
    echo -e "Prometheus configuration file unchanged....$Y SKIPPING $N" | tee -a $LOGFILE
fi

if [ "$NEEDS_RESTART" -eq 1 ]
then
    systemctl daemon-reload &>>$LOGFILE
    VALIDATE $? "Daemon reloading systemd"
else
    echo -e "No config changes detected, skipping daemon-reload....$Y SKIPPING $N" | tee -a $LOGFILE
fi

# Idempotent start
if systemctl is-active --quiet prometheus
then
    if [ "$NEEDS_RESTART" -eq 1 ]
    then
        systemctl restart prometheus &>>$LOGFILE
        VALIDATE $? "Restarting Prometheus service (config changed)"
    else
        echo -e "Prometheus already running, no changes to apply....$Y SKIPPING $N" | tee -a $LOGFILE
    fi
else
    systemctl start prometheus &>>$LOGFILE
    VALIDATE $? "Starting Prometheus service"
fi

# Idempotent enable
if systemctl is-enabled --quiet prometheus 2>/dev/null
then
    echo -e "Prometheus already enabled....$Y SKIPPING $N" | tee -a $LOGFILE
else
    systemctl enable prometheus &>>$LOGFILE
    VALIDATE $? "Enabling Prometheus service"
fi