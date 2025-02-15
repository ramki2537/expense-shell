#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER=$"/var/log/rama"
LOG_FILE=$( echo $0 | cut -d "." -f1 )
TIMESTAMP=$( date +%Y-%m-%d-%H-%M-%S )
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"


VALIDATE(){
if [ $1 -ne 0 ]
then
  echo -e "$2...$R FAILED $N"
  exit 1
else
   echo -e "$2...$G SUCCESS $N"
fi
}

CHECK_ROOT(){
if [ $? -ne 0 ]
then 
   echo "Error: You need admin access to perform this code"
   exit 1
fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing mysql-server"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling mysql-server service"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting mysql-server service"

mysql -h mysql.gonew.io -u root -pExpenseApp@1 'show databases;' &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
   echo "Mysql root password not setup" &>>$LOG_FILE_NAME
   mysql_secure_installation --set-root-pass ExpenseApp@1
   VALIDATE $? "Setting Root password"
else
   echo -e "Root password already setup.....$Y SKIPPING $N"
fi