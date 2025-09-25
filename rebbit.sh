#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"

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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbit repo"

dnf list installed rabbitmq-server &>>$LOG_FILE


if [ $? -ne 0 ]; then
    dnf install rabbitmq-server -y &>>$LOG_FILE
    VALIDATE $? "mongodb-org"
else
    echo -e "rabbitmq-serveralready exist ... $Y SKIPPING $N"
fi

systemctl enable rabbitmq-server
VALIDATE $? "enabling rabbit DB"

systemctl start rabbitmq-server


rabbitmqctl add_user roboshop roboshop123
VALIDATE $? "add user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

VALIDATE $? "set permission"


