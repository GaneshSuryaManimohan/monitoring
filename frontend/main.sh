#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

set -e 
failure(){
    echo "ERROR on line $1:$2"
}
trap 'failure "${LINENO}" "$BASH_COMMAND"' ERR

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

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling Nginx service"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing default Nginx html files"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading frontend zip file"

cd /usr/share/nginx/html &>>$LOGFILE
VALIDATE $? "Changing directory to /usr/share/nginx/html"

unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Extracting frontend zip file"

cp -f /home/ec2-user/monitoring/frontend/expense.conf /etc/nginx/default.d/expense.conf &>>$LOGFILE
VALIDATE $? "Copying expense.conf to /etc/nginx/default.d/"


systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting Nginx service"

cp -f /home/ec2-user/monitoring/frontend/elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo &>>$LOGFILE
VALIDATE $? "Installing Elasticsearch repo"

yum install filebeat -y &>>$LOGFILE
VALIDATE $? "Installing Filebeat"

# After Installing filebeat, make the following changes in the /etc/filebeat/filebeat.yml file
# vim /etc/filebeat/filebeat.yml
# Set enabled: true under filebeat.inputs
# Under paths: modify the log path to /var/log/nginx/access.log
# Specify the elasticsearch IP address for the host variable under output.elasticsearch section
# And then do: systemctl start filebeat