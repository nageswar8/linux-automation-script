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


dnf module disable redis -y

VALIDATE $? "disable redis"
dnf module enable redis:7 -y

VALIDATE $? "enable redis"

dnf list installed redis &>>$LOG_FILE


if [ $? -ne 0 ]; then
    dnf install redis -y &>>$LOG_FILE
    VALIDATE $? "redis"
else
    echo -e "redis already exist ... $Y SKIPPING $N"
fi


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

systemctl enable redis 
VALIDATE $? "enabling "
systemctl start redis 
VALIDATE $? "starting "

ED_TM=$( date +%s)

DU=$(($ED_TM - $EX_ST))
echo -e "Execution time $Y $DU secodns $N"
