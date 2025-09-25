#!/bin/bash

EX_ST=$( date +%s )

USERID=$(id -u)

DB_HOST=mysql.idiap.shop

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
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

dnf list installed maven &>>$LOG_FILE


if [ $? -ne 0 ]; then
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "maven"
else
    echo -e "maven already exist ... $Y SKIPPING $N"
fi


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user"
else
    echo "Roboshop user already created"
fi

mkdir -p /app

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading user"
cd /app 

unzip /tmp/shipping.zip

VALIDATE $? "Unzip ship"

cd /app 
mvn clean package 
VALIDATE $? "packaging"
mv target/shipping-1.0.jar shipping.jar 

VALIDATE $? " moving jar"

cp $CUR_DIR/shipping.service /etc/systemd/system/shipping.service

VALIDATE $? "service created"

systemctl daemon-reload
VALIDATE $? " Daemone reload "
systemctl enable shipping 
VALIDATE $? " Enabling shipping "
systemctl start shipping

VALIDATE $? " starting shipping "

dnf list installed mysql &>>$LOG_FILE


if [ $? -ne 0 ]; then
    dnf install mysql -y &>>$LOG_FILE
    VALIDATE $? "mysql"
else
    echo -e "mysql already exist ... $Y SKIPPING $N"
fi


TABLE_COUNT=$(mysql -h"$DB_HOST" -uroot  -pRoboShop@1 -Ddb -se "SHOW TABLES;" | wc -l)

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "✅ Database there "
else
    mysql -h $DB_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $DB_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql
    mysql -h $DB_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
fi

systemctl restart shipping

VALIDATE $? "restarting shipping"