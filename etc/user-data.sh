#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
yum install -y nodejs

yum -y update
yum install ruby
yum install -y wget
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto > /tmp/logfile
service codedeploy-agent restart

echo "Create Code directory"
mkdir -p /home/ec2-user/node-codedeploy

touch /etc/systemd/system/node-api.service
bash -c 'cat <<EOT > /etc/systemd/system/node-api.service
[Unit]
Description=Nodejs hello world App
Documentation=https://example.com
After=network.target
[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/node /home/ec2-user/node-codedeploy/index.js
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOT'

systemctl enable node-api.service
systemctl start node-api.service