#!/bin/bash

apt-get update
apt-get install default-jre awscli -y

# Download JAR file
aws s3 cp s3://spring-restapi-bucket/spring-boot-rest-api-tutorial.jar ./ 

# Set environment variables as appropriate
export DB_HOST=$(aws ssm get-parameters --names "spring-boot-rest-api-db-host" --query "Parameters[0].Value" --output text)
export DB_USERNAME=$(aws ssm get-parameters --names "spring-boot-rest-api-db-username" --query "Parameters[0].Value" --output text)
export DB_PASSWORD=$(aws ssm get-parameters --names "spring-boot-rest-api-db-password" --query "Parameters[0].Value" --output text)

java -jar spring-boot-rest-api-tutorial.jar
