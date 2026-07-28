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

if yum list installed "java-11*" &>>"$LOGFILE"
then
    echo -e "Java 11 already installed....$Y SKIPPING $N" | tee -a "$LOGFILE"
else
    echo -e "Installing Java 11....$Y IN PROGRESS $N" | tee -a "$LOGFILE"
    yum install java-11-openjdk-devel -y &>>"$LOGFILE"
    VALIDATE $? "Installing Java 11"
fi


cp -f /home/ec2-user/monitoring/elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo &>>$LOGFILE
VALIDATE $? "Copying elasticsearch.repo to /etc/yum.repos.d/"

if yum list installed "elasticsearch" &>>$LOGFILE
then
    echo -e "elasticsearch already installed....$Y SKIPPING $N" | tee -a $LOGFILE
else
    echo -e "Installing elasticsearch....$Y IN PROGRESS $N" | tee -a $LOGFILE
    yum install elasticsearch -y &>>$LOGFILE
    VALIDATE $? "Installing elasticsearch"
fi

cp -f /home/ec2-user/monitoring/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml &>>$LOGFILE
VALIDATE $? "Copying elasticsearch.yml to /etc/elasticsearch/"

systemctl restart elasticsearch
VALIDATE $? "Restarting elasticsearch service"

curl localhost:9200 | tee -a $LOGFILE
VALIDATE $? "Elasticsearch is Running and Reacheable on localhost:9200"

systemctl enable elasticsearch &>>$LOGFILE
VALIDATE $? "Enabling elasticsearch service to start on boot"


#### Install Kibana ####

if  yum list installed kibana* &>>$LOGFILE
then
    echo -e "Kibana already installed....$Y SKIPPING $N" | tee -a $LOGFILE
else
    echo -e "Installing Kibana....$Y IN PROGRESS $N" | tee -a $LOGFILE
    yum install kibana -y &>>$LOGFILE
    VALIDATE $? "Installing Kibana"
fi