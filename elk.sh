#!/bin/bash

set -e
failure(){
    echo "Error on line $1:$2"
}
trap 'failure "${LINENO}" "$BASH_COMMAND"' ERR

if [ $(id -u) -ne 0 ]
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

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIME_STAMP=$(date +%F-%H-%M-%S)
USERID=$(id -u)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIME_STAMP.log

yum list installed java-11* &>>$LOGFILE
VALIDATE $? "Checking if Java 11 is installed"

if [ $? -eq 0 ]
then
    echo -e "Java 11 already installed....$Y SKIPPING $N" | tee -a $LOGFILE
else
    echo -e "Installing Java 11....$Y IN PROGRESS $N" | tee -a $LOGFILE
    yum install java-11-openjdk-devel -y &>>$LOGFILE
    VALIDATE $? "Installing Java 11"
fi


cp -f /home/ec2-user/monitoring/elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo &>>$LOGFILE
VALIDATE $? "Copying elasticsearch.repo to /etc/yum.repos.d/"

yum list installed elasticsearch &>>$LOGFILE
VALIDATE $? "Checking if elasticsearch is installed"

if [ $? -eq 0 ]
then
    echo -e "elasticsearch already installed....$Y SKIPPING $N" | tee -a $LOGFILE
else
    echo -e "Installing elasticsearch....$Y IN PROGRESS $N" | tee -a $LOGFILE
    yum install elasticsearch -y &>>$LOGFILE
    VALIDATE $? "Installing elasticsearch"
fi