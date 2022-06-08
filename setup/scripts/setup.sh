#!/bin/bash

apt-get update
apt-get install default-jre awscli -y

cd /home/ubuntu
sudo -u ubuntu ws s3 cp s3://spring-restapi-bucket/spring-boot-rest-api-tutorial.jar ./ 

DB_HOST=$(aws ssm get-parameters --region us-west-2 --names "spring-boot-rest-api-db-host" --query "Parameters[0].Value" --output text)
DB_USERNAME=$(aws ssm get-parameters --region us-west-2 --names "spring-boot-rest-api-db-username" --query "Parameters[0].Value" --output text)
DB_PASSWORD=$(aws ssm get-parameters --region us-west-2 --names "spring-boot-rest-api-db-password" --query "Parameters[0].Value" --output text)

echo "export DB_HOST="$DB_HOST >> /home/ubuntu/.bashrc
echo "export DB_USERNAME="$DB_USERNAME >> /home/ubuntu/.bashrc
echo "export DB_PASSWORD="$DB_PASSWORD >> /home/ubuntu/.bashrc

export DB_HOST=$DB_HOST
export DB_USERNAME=$DB_USERNAME
export DB_PASSWORD=$DB_PASSWORD

sudo -u ubuntu java -jar spring-boot-rest-api-tutorial.jar
