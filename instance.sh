echo "Hello, I came here to automate"


DOMAIN_NAME="idiap.shop"

for i in "$@"
do 
    INSTANCE_ID=$(aws ec2 run-instances  --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0fecc4fefc0ae3b31 --region us-east-1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].InstanceId' --output text)
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ "$i" != "frontend" ]; then 
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
        aws route53 change-resource-record-sets  --hosted-zone-id Z09590552TMQIL7M10P1I \
        --change-batch '{
        "Comment": "Creating an A record",
        "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$DOMAIN_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                    {
                        "Value": "'$IP'"
                    }
                ]
            }
        }
    ]
}'
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].PublicIpAddress' --output text)
        aws route53 change-resource-record-sets  --hosted-zone-id Z09590552TMQIL7M10P1I \
        --change-batch '{
        "Comment": "Creating an A record",
        "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$i.$DOMAIN_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                    {
                        "Value": "'$IP'"
                    }
                ]
            }
        }
    ]
}'
    fi
done
