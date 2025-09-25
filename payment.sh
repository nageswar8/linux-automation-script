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

dnf install python3 gcc python3-devel -y
VALIDATE $? "install python"


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user"
else
    echo "Roboshop patment already created"
fi

mkdir -p /app

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment"
cd /app 

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? " Remove old code "
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment"

cd /app 
pip3 install -r requirements.txt &>>LOG_FILE

VALIDATE $? "install dependecies"

cp $CUR_DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable payment 
VALIDATE $? "enabing payment reload"

systemctl start payment

VALIDATE $? "start payment reload"
