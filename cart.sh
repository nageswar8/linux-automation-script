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

dnf module list nodejs &>>$LOG_FILE

VALIDATE $? "getting the node list"

dnf module disable nodejs -y &>>$LOG_FILE

VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable 20 nodejs"

dnf install nodejs -y &>>$LOG_FILE

VALIDATE $? "installing nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user"
else
    echo "Roboshop user already created"
fi

mkdir -p /app

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading cart"
cd /app 

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? " Remove old code "
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzip cart"

npm install &>>$LOG_FILE

VALIDATE $? "install dependencies"

cp $CUR_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying service"

systemctl daemon-reload
VALIDATE $? "reloading daemon"

systemctl enable cart &>>$LOG_FILE 
VALIDATE $? "enable cart"
systemctl start cart &>>$LOG_FILE
VALIDATE $? "start cart"
