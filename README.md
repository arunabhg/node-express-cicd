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
  - [Fix AWS CodeDeploy Failures ](#fix-aws-codedeploy-failures-) - [Deploy process fails at first step with error - Application stop Failed with exit code 1](#deploy-process-fails-at-first-step-with-error---application-stop-failed-with-exit-code-1)

## About <a name = "about"></a>

A project template for creating a CI/CD pipeline to automatically deploy a Node-Express project to EC2 using GitHub Actions and AWS CodeDeploy.

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine. See [deployment steps](#steps) for notes on how to deploy the project using a CI/CD pipeline.

### Prerequisites

You will need a GitHub repo, an AWS account and knowledge of what exactly are EC2, IAM Roles, GitHub Actions and CodeDeploy.

### Steps <a name = "steps"></a>

### Step 1 - Set up EC2 instance

#### 1. Login to AWS console and go to **_EC2 dashboard_**.

#### 2. Click on **_Launch Instance_** under Instances.

#### 3. Give an instance name, description.

#### 4. Click on Quick start to select the AMI & instance type. In our case we're using a 64-bit Linux t2.micro.

#### 5. If you have a key-pair downloaded in your machine, select it from the dropdown; otherwise create one by clicking on the _Create a new key pair_ link.

#### 6. If you already have a Security Group created, select that from dropdown; otherwise create a security group having All inbound open (0.0.0.0) to TCP ports 3000, and 80 and to SSH port 22.

#### 7. Stick with the default storage or use the gp3 storage as it's newer.

### Step 2 - Configure IAM Roles

#### 1. Before proceeding further, we have to create IAM roles for EC2 and CodeDeploy.

#### 2. Open IAM -> Roles in a new tab. Search for CodeDeploy service -> CodeDeploy. Save it as **CodeDeployRole**.

#### 3. Create _another_ role by selecting EC2 and searching for CodeDeploy. Choose **_AmazonEC2RoleForAWSCodeDeploy_** and save the role as **EC2CodeDeployRole**.

#### 4. Going back to the EC2 instance, under IAM role, choose EC2CodeDeployRole in IAM Instance Profile.

#### 5. Leave rest other default options blank. Click on Launch Instance to successfully launch EC2 instance.

### Step 3 - SSH to Linux EC2 and install node, nvm and pm2

#### 1. If you have a Windows machine use Putty else use the terminal in Mac/Linux to SSH into the AMI.

```sh
sudo yum update
```

```sh
sudo yum upgrade
```

```sh
sudo yum install -y git htop wget
```

1.1 Install Node
To install or update nvm, you should run the [install script][2]. To do that, you may either download and run the script manually, or use the following cURL or Wget command:

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```

Or

```sh
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```

Running either of the above commands downloads a script and runs it. The script clones the nvm repository to ~/.nvm, and attempts to add the source lines from the snippet below to the correct profile file (~/.bash_profile, ~/.zshrc, ~/.profile, or ~/.bashrc).

1.2 Copy & Paste (each line separately)

```sh
export NVM_DIR="$HOME/.nvm"
```

```sh
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
```

```sh
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

1.3 Verify that nvm has been installed

```sh
nvm --version
```

1.4 Install node

```sh
nvm install --lts # Latest stable node js server version or replace --lts with a stable nodejs version no
```

1.5 Check nodejs installation

```sh
node --version
```

1.6 Check npm installed

```sh
npm -v
```

2

### Step 2

- Create appspec.yml file and shell scripts for code deploy

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

#### Step 4 - Test the deployed code

1. Go back to the EC2 instance & copy it's public IP.
2. Check if it's running fine on port 3000.
3. Make some changes in your code and check if the pipeline is successful.
4. Check if your changes are visible in the public IP for port 3000.
5. For every change you commit to your repo, it should be visible in a few minutes in the public IP.
6. If everything goes fine, you have created a CI/CD pipeline for your application.

## Fix AWS CodeDeploy Failures <a name = "fixes"></a>

#### Deploy process fails at first step with error - Application stop Failed with exit code 1

1. To fix this, we have to remove the codedeploy-agent. SSH into the terminal (MAC) or Putty (Windows) as per your OS.
2. Delete the codedeploy-agent with command - `sudo yum erase codedeploy-agent`
3. We also have to remove the logs generated by the agent which are kept in /opt/codedeploy-agent. Run the following commands -
   ```
   cd /opt
   ls
   sudo rm -r codedeploy-agent/
   ```
4. Go to the root directory and remove the project folder.
   ```
   cd
   ls
   sudo rm -r node-codedeploy     # here node-codploy is the name of our directory, it can be different in yours
   ```
5. Reinstall code-deploy agent with the following command -
   ```
   sudo ./install auto
   ```
6. Check the codedeploy-agent service is running or not. If the following command throws an error, codedeploy-agent hasn't been installed but if it returns a PID, it is installed & running - `sudo service codedeploy-agent status`.
7. Make some small updates in your code and push to your repository. This time code deploy should succeed.
