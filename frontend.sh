#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
# MONGO_HOST=mongodb.idiap.shop
CUR_DIR=$PWD

if [ $USERID -ne 0 ]; then
    echo -e "$R error:: user need root privileges"
    exit 1 
fi

SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER

echo "Script started executed $(date)" | tee -a $LOG_FILE

VALIDATE() {

    if [ $1 -ne 0 ]; then
        echo -e "Installing $2 ... $R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G Installing $2 ...  SUCCESS $N" | tee -a $LOG_FILE
    fi

}

dnf module list nginx &>>$LOG_FILE

VALIDATE $? "getting the nginx list"

dnf module disable nginx -y &>>$LOG_FILE

VALIDATE $? "Disable nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enable 20 nginx"

dnf install nginx -y &>>$LOG_FILE

VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE 
VALIDATE $? "enable nginx"
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "start nginx"

rm -rf /usr/share/nginx/html/* 

VALIDATE $? " removed contents"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip

VALIDATE $? " download fronend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? " unzp fronend"

cp $CUR_DIR/nginx.conf /etc/nginx/nginx.conf
