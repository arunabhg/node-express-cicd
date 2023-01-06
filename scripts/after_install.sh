#!/bin/bash
echo 'run after_install.sh: ' >> /home/ec2-user/node-express-cicd/deploy.log

echo 'cd /home/ec2-user/nodejs-server-cicd' >> /home/ec2-user/node-express-cicd/deploy.log
cd /home/ec2-user/node-express-cicd >> /home/ec2-user/node-express-cicd/deploy.log

echo 'npm install' >> /home/ec2-user/node-express-cicd/deploy.log 
npm install >> /home/ec2-user/node-express-cicd/deploy.log