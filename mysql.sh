#!/bin/bash

EX_ST=$( date +%s )

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


dnf list installed mysql &>>$LOG_FILE


if [ $? -ne 0 ]; then
    dnf install mysql -y &>>$LOG_FILE
    VALIDATE $? "mysql"
else
    echo -e "mysql already exist ... $Y SKIPPING $N"
fi

systemctl enable mysql 
VALIDATE $? "enabling "
systemctl start mysql 
VALIDATE $? "starting "

mysql_secure_installation --set-root-pass RoboShop@1

VALIDATE $? "set pass for mysql "