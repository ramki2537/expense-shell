#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/rama"
LOG_FILE=$( echo $0 | cut -d "." -f1 )
TIMESTAMP=$( date +%Y-%m-%d-%H-%M-%S )
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"


VALIDATE(){
    if [ $1 -ne 0 ]
    then 
          echo -e "$2...$R FAILURE $N"
          exit 1
    else
          echo -e "$2...$G SUCCESS $N"
    fi
}

CHECK_ROOT(){

if [ $USERID -ne 0 ]
then
    echo "Error: You need admin access to run this script"
    exit 1
fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling noodejs old version"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $?  "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Install nodejs"

useradd expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "Expense user already exists...$Y SKIPPING $N"
fi

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"


curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend code"

cd /app

unzip /tmp/backend.zip
VALIDATE $? "Unzip backend"

npm install
VALIDATE $? "Installing dependencies"

cp /root/expense-shell/backend.service /etc/systemd/system/backend.service

# Prepare SQL Schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql client"

mysql -h mysql.gonew.io -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Reloading deamon service"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend service"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting backend serivce"

