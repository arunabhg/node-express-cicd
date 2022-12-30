# node-express-cicd

## Table of Contents

- [node-express-cicd](#node-express-cicd)
	- [Table of Contents](#table-of-contents)
	- [About ](#about-)
	- [Getting Started ](#getting-started-)
		- [Prerequisites](#prerequisites)
		- [Steps ](#steps-)
			- [Step 1 - Set up EC2, and IAM roles](#step-1---set-up-ec2-and-iam-roles)
			- [Step 2 - Create appspec.yml file and shell scripts for code deploy](#step-2---create-appspecyml-file-and-shell-scripts-for-code-deploy)
			- [Step 3 - Set up CodeDeploy](#step-3---set-up-codedeploy)
			- [Step 4 - Set up Pipeline](#step-4---set-up-pipeline)
			- [Step 5 - Test the deployed code](#step-5---test-the-deployed-code)
	- [Usage ](#usage-)

## About <a name = "about"></a>

A project template for creating a CI/CD pipeline to deploy a Node-Express TypeScript project in EC2 stored in S3 bucket using GitHub Actions and OIDC.

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine. See [deployment steps](#steps) for notes on how to deploy the project using a CI/CD pipeline.

### Prerequisites

You will need a GitHub repo, an AWS account and knowledge of what exactly are EC2, S3, IAM Roles.

### Steps <a name = "steps"></a>

#### Step 1 - Set up EC2, and IAM roles

1. Login to AWS console and go to **_EC2 dashboard_**.
2. Click on **_Launch Template_** under Instances. A _launch template_ allows you to create a saved instance configuration that can be reused, shared and launched at a later time.
3. Click on **_Create Launch Template_**, if one isn't already created.
4. Give a template name, description, uncheck the Auto Scaling Guidance and we don't need to select a Source Template, if we are starting from scratch.
5. Click on Quick start to select the AMI & instance type. In our case we're selecting 64-bit Linux t2.micro.
6. If you have a key-pair downloaded in your machine, select it from the dropdown; otherwise create one by clicking on the _Create a new key pair_ link.
7. If you already have a Security Group created, select that from dropdown; otherwise create a security group having All inbound open (0.0.0.0) to port 3000. We don't need to SSH in this case. Opening port 3000 is enough.
8. Stick with the default storage.
9. In the resource tags, we'll add two resource tags having key-value of `template`-`yes` and `Name`-`node-server`. These key-value pairs will be applied to all resource tags which are of instances types.
10. We want all EC2 instances created from this launch template to have a role of CodeDeploy. So before proceeding further with the Advanced Details, we have to create IAM roles for CodeDeploy.
11. Open IAM -> Roles. Search for CodeDeploy service -> CodeDeploy. Save it as CodeDeployRole.
12. Create _another_ role by selecting EC2 and searching for CodeDeploy. Choose AmazonEC2RoleForAWSCodeDeploy and save the role as EC2CodeDeployRole.
13. Going back to the Launch template, under Advanced details, choose EC2CodeDeployRole in IAM Instance Profile.
14. Leave rest other default options blank.
15. Finally, in User Data add the following shell script for deploying and running the project.

```shell

#!/bin/bash
sudo yum -y update
sudo yum -y install ruby
sudo yum -y install wget
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
```

**Explanation:** In the above shell script first we update. Then we install ruby and install wget. We cd into our ec2-user folder in home directory. We install codedeploy and s3 bucket for our region.<br />

1.  Click on Create Launch Template to successfully create the template.<br/> _Note-_ We can create multiple versions of the template and use one as a default version.
2.  To create an instance from this template, select the template, go to _Actions_ -> _Launch instance from template_. Keep everything default and click on _Launch Instance_ to create a new server instance. <br />
    The EC2 instance created will have a name of _node-server_ which we had specified in the resource tag (in Step 9).

#### Step 2 - Create appspec.yml file and shell scripts for code deploy

1. Create an **_appspec.yml_** file in your project's root directory which is required for code deploy.
2. It includes the version no of the app, the os on which it needs to be deployed, the file source, the file destination on the server, the actions (hooks) that we will run on the files which includes an application start script, before install and an application ending script. It's structure -

```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /home/ec2-user/node-codedeploy
hooks:
  ApplicationStop:
    - location: scripts/application_stop.sh
      timeout: 300
      runas: ec2-user
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 300
      runas: ec2-user
  ApplicationStart:
    - location: scripts/application_start.sh
      timeout: 300
      runas: ec2-user
```

3. Add a folder call _scripts_ where you add the above scripts.
4. Application Stop - If there are any existing node servers, stop them.
5. Before Install - Install nvm and node. If a directory exists in our ec2-user, create one named node-codedeploy.
6. Application Start - Navigate to the node-codedeploy directory, add npm and node to the PATH, add the node_modules folder, build using tsc and run node in background.

#### Step 3 - Set up CodeDeploy

1. Go to CodeDeploy inside AWS Console.
2. Click on _Applications -> Create Application_.
3. Give the _Application Name_ as the one (--application-name) which you have specified in your GitHub Action's YAML file in your destination folder. In our case it is `node-codedeploy`. <br />
4. Compute Platform will be _EC2/On-premises_. Click on Create Application.
5. App is successfully created. Next click on _Create Deployment Group_ in the application. Lets call it `ec2-app-group`.
6. Choose the CodeDeployRole in the Service Role.
7. Keep the default in-place selection for Deployment Type.
8. Select the EC2 instance by it's `Name` key which we had set as `node-server`. When you select this, it should show the Matching instances. If this was your first instance with this key, it will say, `1 unique matched instance`.
9. For Agent Configuration. leave as default.
10. In Deployment Settings, _CodeDeploy.DefaultAllAtOnce_ should be selected.
11. Uncheck the Load Balancer, as we have only one instance & we won't need it. Click on _Create Deployment Group_.

#### Step 4 - Set up Pipeline

1. Go to Pipeline -> Create Pipeline.
2. Give the pipeline a name. For eg., `node-app-pipeline`.
3. AWS creates a Service Role automatically based on the pipeline name.
4. We can choose a default location to hold the source code/deployment package. We can choose a custom S3 bucket OR let CodePipeline create the default bucket for you. If it's a small app, we can choose default location. For production, we should specify a custom S3 bucket.
5. Click Next & Select GitHub (version 2) in Source.
6. In Connection, choose a connection if you already have one. If it's your first time connecting to Pipeline, click on Connect to GitHub.
7. Give the connection a name & click Connect to GitHub. Click Install a New App, Sign in to GitHub & select which repository you want to give access to. Click Save & then hit Connect to create a connection.
8. Once the connection is made successfully, choose the repo name and branch name.
9. Click Next.
10. You can skip the optional build stage & click Next.
11. In Deploy part, select your AWS CodeDeploy as Deploy Provider, your application name, the name of the deployment group, and click Next.
12. Preview the details you entered for the pipeline. If everything looks okay, click on Create Pipeline.
13. Once the Pipeline is created, you can check each part by clicking on View Details and see if the Pipeline is successfully running.

#### Step 5 - Test the deployed code

1. Go back to the EC2 instance & copy it's public IP.
2. Check if it's running fine on port 3000.
3. Make some changes in your code and check if the pipeline is successful.
4. Check if your changes are visible in the public IP for port 3000.
5. For every change you commit to your repo, it should be visible in a few minutes in the public IP.
6. If everything goes fine, you have created a CI/CD pipeline for your application.

## Usage <a name = "usage"></a>

Add notes about how to use the system.
