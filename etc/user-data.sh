#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
sudo yum -y install nodejs

sudo yum -y update
sudo yum -y install ruby
sudo yum -y install wget
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto > /tmp/logfile
sudo service codedeploy-agent restart

echo "Create Code directory"
mkdir -p /node-codedeploy

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