# node-express-cicd

## Table of Contents

- [node-express-cicd](#node-express-cicd)
	- [Table of Contents](#table-of-contents)
	- [About ](#about-)
	- [Getting Started ](#getting-started-)
		- [Prerequisites](#prerequisites)
		- [Steps ](#steps-)
			- [Step 1 - Set up EC2, IAM roles](#step-1---set-up-ec2-iam-roles)
			- [Step 2 - Configure GitHub Actions using OIDC](#step-2---configure-github-actions-using-oidc)
			- [Step 3 - Set up CodeDeploy](#step-3---set-up-codedeploy)
	- [Usage ](#usage-)

## About <a name = "about"></a>

A project template for creating a CI/CD pipeline to deploy a Node-Express TypeScript project in EC2 stored in S3 bucket using GitHub Actions and OIDC.

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See [deployment](#deployment) for notes on how to deploy the project on a live system.

### Prerequisites

You will need a GitHub repo, an AWS account and knowledge of what exactly are EC2, S3, OIDC (Open ID Connect), GitHub Actions.

See [OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) and [AWS-Actions](https://github.com/aws-actions/configure-aws-credentials) to get an understanding of how OIDC works.

### Steps <a name = "steps"></a>

#### Step 1 - Set up EC2, IAM roles

1. Login to AWS console and go to **_EC2 dashboard_**.
2. Click on **_Launch Template_** under Instances. A _launch template_ allows you to create a saved instance configuration that can be reused, shared and launched at a later time.
3. Click on **_Create Launch Template_**, if one isn't already created.
4. Give a template name, description, uncheck the Auto Scaling Guidance and we don't need to select a Source Template, if we are starting from scratch.
5. Click on Quick start to select the AMI & instance type. In our case we're selecting 64-bit Linux t2.micro.
6. If you have a key-pair downloaded in your machine, select it from the dropdown; otherwise create one by clicking on the _Create a new key pair_ link.
7. If you already have a Security Group created, select that from dropdown; otherwise create a security group having All inbound open (0.0.0.0) to port 3000. We don't need to SSH in this case. Opening port 3000 is enough.
8. Stick with the default storage.
9. In the resource tags, we'll add two resource tags having key-value of `template`-`yes` and `Name`-`node-server`. These key-value pairs will be applied to all resource tags which are of instances types.
10. We want all instances created from this launch template to have a role of CodeDeploy. So before proceeding further with the Advanced Details, we have to create an IAM role for CodeDeploy.
11. Open IAM. Create an EC2-Role with S3FullAccess and CodeDeployFullAccess.
12. Going back to the Launch template, under Advanced details, choose EC2-Role in IAM Instance Profile.
13. Leave rest other default options blank.
14. Finally, in User Data add the following shell script for deploying and running the project.

```shell

#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

apt update
apt install ruby-full -y
apt install wget -y
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto > /tmp/logfile
service codedeploy-agent restart

echo "Create Code directory"
mkdir -p /home/linux/Code/node-codedeploy

touch /etc/systemd/system/node-api.service
bash -c 'cat <<EOT > /etc/systemd/system/node-api.service
[Unit]
Description=Nodejs hello world App
Documentation=https://example.com
After=network.target
[Service]
Type=simple
User=ec2-user
ExecStart=/usr/bin/node /home/linux/Code/node-codedeploy/dist/index.js
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOT'

systemctl enable node-api.service
systemctl start node-api.service
```

15. Click on Create Launch Template to successfully create the template.
16. We can create multiple versions of the template to use a default version.
17. To create an instance from this template, select the template, go to _Actions_ -> _Launch instance from template_. Keep everything default and click on _Launch Instance_ to create a new server instance. <br />
    The EC2 instance created will have a name of _node-server_ which we had specified in the resource tag (in Step 9).

#### Step 2 - Configure GitHub Actions using OIDC

1. Go to AWS Console -> IAM -> Identity Provider. Click on _Add Provider_.
2. Select OpenID Connect.

- For the provider role, use: `https://token.actions.githubusercontent.com`
  Get the thumbprint.
- For the audience, use: `sts.amazonaws.com`. This is like the OAuth.

3. Click on _Add Provider_. We have the provider created.
4. We have to assign a role to this provider. Go to IAM -> Roles. Create a role named with S3FullAccess and CodeDeployFullAccess to the identity provider. As this role will be used in GitHub Actions, you can name this role as "GitHub-Actions-Deploy-Role". (_Note-_ Role name can be as per your choice)
5. Create a GitHub Actions YAML file in your project's workflow (.github/workflows) which manages the CI/CD.
6. This Actions file contains one secret (IAMROLE*GITHUB) which needs to be added to GitHub's settings.<br /> For this go to your repo's Settings -> scroll down to Security -> Secrets -> Actions. Click on \_New repository secret*, get the _arn_ of "GitHub-Actions-Deploy-Role" and paste it here. This secret will be accessed in the workflow.<br />
   The GitHub Actions is ready and we need to next setup CodeDeploy.

#### Step 3 - Set up CodeDeploy

1. Go to CodeDeploy inside AWS Console.
2. Click on _Applications -> Create Application_.
3. Give the _Application Name_ as the one (--application-name) which you have specified in your GitHub Action's YAML file in your project's workflow folder. In our case it is `node-app`. <br />
   _Note-_ All the names for the CodeDeploy part are pre-configured in the YAML file at the `run` section at the end. The names in the file and those in CodeDeploy should match, otherwise it will give an error while running.
4. Compute Platform will be _EC2/On-premises_. Click on Create Application.
5. App is successfully created. Next click on _Create Deployment Group_ in the application.
6. The deployment group name will also be taken from the YAML file. In our case (--deployment-group-name), it is `ec2-app`.
7. Create a role for CodeDeployService in IAM which includes permission for deploying to EC2, S3. Copy the arn for the IAM Service role and paste it in Service Role.
8. Keep the default in-place selection for Deployment Type.
9. Select the EC2 instance by it's `Name` key which we had set as `node-server`. When you select this, it should show the Matching instances. If this was your first instance with this key, it will say, `1 unique matched instance`.
10. In AWS CodeDeploy Agent, select _Never_ as we will be deploying the code using User Data.
11. In Deployment Settings, _CodeDeploy.DefaultAllAtOnce_ should be selected.
12. Uncheck the Load Balancer, as we won't be using it. Click on _Create Deployment Group_.

## Usage <a name = "usage"></a>

Add notes about how to use the system.
