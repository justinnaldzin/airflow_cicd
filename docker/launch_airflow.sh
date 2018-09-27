#!/bin/bash

# install dependencies
yum update -y
yum install -y gcc-c++
yum install -y python-setuptools python-pip
yum install -y docker git jq
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
pip install docker-compose
pip install awscli --upgrade

# retrieve GitLab credentials from Secrets Manager
GIT_SECRETSTRING=$(aws secretsmanager get-secret-value --secret-id git --region us-east-1 --region us-east-1 --query SecretString | jq -r .)
GIT_USER=$(echo $GIT_SECRETSTRING | jq -r .git_user)
GIT_PASSWORD=$(echo $GIT_SECRETSTRING | jq -r .git_password)
GIT_URL=$(echo $GIT_SECRETSTRING | jq -r .git_url)

# clone GitLab repo and checkout branch
REPO_PATH=/opt/data_warehouse
mkdir -p ${REPO_PATH}
chmod -R 777 ${REPO_PATH}
BRANCH=master
git clone https://${GIT_USER}:${GIT_PASSWORD}@${GIT_URL} ${REPO_PATH}
cd ${REPO_PATH}
git checkout $BRANCH

# build the docker image from the `Dockerfile` and start Airflow containers
cd docker
docker build --rm -t justinnaldzin/docker-airflow .
docker-compose up --detach
