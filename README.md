# How to set CI/CD for a Node.js/Express app using GitHub Actions and AWS CodeDeploy

## Table of Contents

- [node-express-cicd](#node-express-cicd)
  - [Table of Contents](#table-of-contents)
  - [About ](#about-)
  - [Getting Started ](#getting-started-)
    - [Prerequisites](#prerequisites)
    - [Steps ](#steps-)
    - [Step 1 - Set up EC2 instance](#step-1---set-up-ec2-instance)
    - [Step 2 - Configure IAM Roles](#step-2---configure-iam-roles)
    - [Step 3 - SSH to Linux EC2 and install node, nvm and pm2](#step-3---ssh-to-linux-ec2-and-install-node-nvm-and-pm2)
    - [Step 4. Go to ec2-user directory and clone the repository](#step-4-go-to-ec2-user-directory-and-clone-the-repository)
    - [Step 5 - Configure appspec.yml and hooks](#step-5---configure-appspecyml-and-hooks)
    - [Step 6 - Run node.js \& make sure everything is working before moving to next step](#step-6---run-nodejs--make-sure-everything-is-working-before-moving-to-next-step)
    - [Step 7 - Install pm2 (globally)](#step-7---install-pm2-globally)
    - [Step 8 - Set node, pm2 and npm available to root (as we are running scripts as _root_ in appspec.yml)](#step-8---set-node-pm2-and-npm-available-to-root-as-we-are-running-scripts-as-root-in-appspecyml)
    - [Step 9 - Starting the app as sudo using pm2 with an alias (Run app in background and when server restarts)](#step-9---starting-the-app-as-sudo-using-pm2-with-an-alias-run-app-in-background-and-when-server-restarts)
    - [Step 10 - Install AWS CodeDeploy Agent](#step-10---install-aws-codedeploy-agent)
    - [Step 11 - Set up CodeDeploy](#step-11---set-up-codedeploy)
      - [Create Application](#create-application)
      - [Create Deployment Group](#create-deployment-group)
    - [Step 12 - Connect CodeDeploy with GitHub](#step-12---connect-codedeploy-with-github)
    - [Step 13 - Test Deployment](#step-13---test-deployment)
  - [Fix AWS CodeDeploy Failures ](#fix-aws-codedeploy-failures-)
      - [Deploy process fails at first step with error - Application stop Failed with exit code 1](#deploy-process-fails-at-first-step-with-error---application-stop-failed-with-exit-code-1)

## About <a name = "about"></a>

A project template for creating a CI/CD pipeline to automatically deploy a Node-Express project to EC2 using GitHub Actions and AWS CodeDeploy.

## Getting Started <a name = "getting_started"></a>

These instructions will get you a copy of the project up and running on your local machine. See [deployment steps](#steps) for notes on how to deploy the project using a CI/CD pipeline.

### Prerequisites

You will need a GitHub repo, an AWS account and basic knowledge of what exactly are EC2, IAM Roles, GitHub Actions and CodeDeploy.

### Steps <a name = "steps"></a>

### Step 1 - Set up EC2 instance

1.1 Login to AWS console and go to **_EC2 dashboard_**.

1.2 Click on **_Launch Instance_** under Instances.

1.3 Give an instance name, description.

1.4 Click on Quick start to select the AMI & instance type. In our case we're using a 64-bit Linux t2.micro.

1.5 If you have a key-pair downloaded in your machine, select it from the dropdown; otherwise create one by clicking on the _Create a new key pair_ link.

1.6 If you already have a Security Group created, select that from dropdown; otherwise create a security group having All inbound open (0.0.0.0) to TCP ports 3000, and 80 and to SSH port 22.

1.7 Stick with the default storage or use the gp3 storage as it's newer.

### Step 2 - Configure IAM Roles

2.1 Before proceeding further, we have to create IAM roles for EC2 and CodeDeploy.

2.2 Open IAM -> Roles in a new tab. Search for CodeDeploy service -> _CodeDeploy_. Save it as **CodeDeployRole**.

2.3 Create _another_ role by selecting EC2 and searching for CodeDeploy. Choose **_AmazonEC2RoleForAWSCodeDeploy_** and save the role as **EC2CodeDeployRole**.

2.4 Going back to the EC2 instance, under IAM role, choose EC2CodeDeployRole in IAM Instance Profile.

2.5 Leave rest other default options blank. Click on Launch Instance to successfully launch EC2 instance.

### Step 3 - SSH to Linux EC2 and install node, nvm and pm2

3.1 If you have a Windows machine use Putty else use the terminal in Mac/Linux to SSH into the AMI.

```sh
sudo yum update
```

```sh
sudo yum upgrade
```

```sh
sudo yum install -y git htop wget
```

3.2 Install Node
To install or update nvm, you should run the [install script][2]. To do that, you may either download and run the script manually, or use the following cURL or Wget command:

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```

Or

```sh
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```

Running either of the above commands downloads a script and runs it. The script clones the nvm repository to \~/.nvm, and attempts to add the source lines from the snippet below to the correct profile file (\~/.bash_profile, ~/.zshrc, ~/.profile, or ~/.bashrc).

3.3 Copy & Paste (each line separately)

```sh
export NVM_DIR="$HOME/.nvm"
```

```sh
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
```

```sh
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

3.4 Verify that nvm has been installed

```sh
nvm --version
```

3.5 Install node

```sh
nvm install --lts # Latest stable node js server version or replace --lts with a stable nodejs version no
```

3.6 Check nodejs installation

```sh
node -v
```

3.7 Check npm installed

```sh
npm -v
```

### Step 4. Go to ec2-user directory and clone the repository

```sh
cd /home/ec2-user
```

```sh
git clone https://github.com/arunabhg/node-express-cicd.git
```

**_Note-_** Replace the repository link with your relevant repo link.

### Step 5 - Configure appspec.yml and hooks

- Create appspec.yml file and shell scripts for code deploy

  5.1 Create an **_appspec.yml_** file in your project's root directory which is required for code deploy.

  5.2 It includes the version no of the app, the os on which it needs to be deployed, the file source, the file destination on the server, the actions (hooks) that we will run on the files which includes an application start script, and an after install script. It's structure -

```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /home/ec2-user/node-express-cicd
    overwrite: true
hooks:
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 900
      runas: root
  ApplicationStart:
    - location: scripts/application_start.sh
      timeout: 900
      runas: root
```

5.3 Add a folder call _scripts_ where you add the above scripts.

5.4 After Install - cd to the node-express-cicd directory in the server and run `npm install` to add all packages in the folder.

5.5 Application Start - Restart the pm2 package.

### Step 6 - Run node.js & make sure everything is working before moving to next step

```sh
cd node-express-cicd
```

```sh
npm install
```

```sh
node index.js
```

### Step 7 - Install pm2 (globally)

```sh
npm install -g pm2 # may require sudo
```

### Step 8 - Set node, pm2 and npm available to root (as we are running scripts as _root_ in appspec.yml)

```sh
sudo ln -s "$(which node)" /sbin/node
```

```sh
sudo ln -s "$(which npm)" /sbin/npm
```

```sh
sudo ln -s "$(which pm2)" /sbin/pm2
```

### Step 9 - Starting the app as sudo using pm2 with an alias (Run app in background and when server restarts)

```sh
sudo pm2 start index.js --name nodejs-express-app
```

```sh
sudo pm2 save     # saves the running processes
                  # if not saved, pm2 will forget
                  # the running apps on next boot
```

9.1 **_IMPORTANT:_** If you want pm2 to start on system boot

```sh
sudo pm2 startup # starts pm2 on computer boot
```

### Step 10 - Install AWS CodeDeploy Agent

```sh
sudo yum install -y ruby
```

```sh
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
```

**_IMPORTANT_** - Change the AWS region accordingly.

```sh
chmod +x ./install
```

```sh
sudo ./install auto
```

```sh
sudo service codedeploy-agent start
```

### Step 11 - Set up CodeDeploy

11.1 Go to CodeDeploy inside AWS Console.

#### Create Application

11.2 Click on _Applications -> Create Application_.

11.3 Give the _Application Name_ as the one (--application-name) which you have specified in your GitHub Action's deploy file (YAML) in your destination folder. In our case it is `nodejs-express-app`. <br />

11.4 Compute Platform will be _EC2/On-premises_. Click on Create Application.

#### Create Deployment Group

11.5 App is successfully created. Next click on _Create Deployment Group_ in the application. Lets call it `nodejs-express-app-d1`.

11.6. Choose the CodeDeployRole in the Service Role.

11.7. Keep the default in-place selection for Deployment Type.

11.8 Select the EC2 instance by it's `Name` key which we had set as `node-server`. When you select this, it should show the Matching instances. If this was your first instance with this key, it will say, `1 unique matched instance`.

11.9 For Agent Configuration. leave as default.

11.10. In Deployment Settings, _CodeDeploy.OneAtATime_ should be selected.

11.11 Uncheck the Load Balancer, as we have only one instance & we won't need it. Click on _Create Deployment Group_.

### Step 12 - Connect CodeDeploy with GitHub

12.1 Go to the Deployment group you have just created and click on _Create Deployment_.

12.2 Go to your GitHub profile -> Settings -> Applications, and create a new token.

12.3 Use this token as the source for the deployment.

12.4 Go to your repo. Copy the repo name (<username>/<repository>) and give it as the repository name.

12.5 Make a minor change in your repo's file and commit. After committing, copy & paste the commit ID (the text after the repo name in a commit) where asked.

12.6 Save and wait for CodeDeploy to finish all steps.

12.7 If all steps proceed without any error, connection with GitHub is successful. Move to last step.

### Step 13 - Test the Deployment

13.1 Go back to the EC2 instance & copy it's public IP.

13.2 Check if it's running fine on port 3000.

13.3. Again commit some changes in your code and check if the CI/CD process is successful, from GitHub Actions to CodeDeploy.

13.4 Check if your changes are visible in the public IP for port 3000.

13.5 For every change you commit to your repo, it should be visible in a few minutes in the public IP.

13.6. If everything goes fine, you have created a working CI/CD pipeline for your application.

## Fix AWS CodeDeploy Failures <a name = "fixes"></a>

#### Deploy process fails at first step with error - Application stop Failed with exit code 1

1. To fix this, we have to remove the codedeploy-agent. SSH into the terminal (MAC) or Putty (Windows) as per your OS.
2. Delete the codedeploy-agent with command - `sudo yum erase codedeploy-agent`
3. We also have to remove the logs generated by the agent which are kept in /opt/codedeploy-agent. Run the following commands -
   ```sh
   cd /opt
   ls
   sudo rm -r codedeploy-agent/
   ```
4. Go to the root directory and remove the project folder.
   ```sh
   cd
   ls
   sudo rm -r nodejs-express-app    # replace the directory name with yours
   ```
5. Reinstall code-deploy agent with the following command -
   ```sh
   sudo ./install auto
   ```
6. Check the codedeploy-agent service is running or not. If the following command throws an error, codedeploy-agent hasn't been installed but if it returns a PID, it is installed & running - `sudo service codedeploy-agent status`.
7. Make some small updates in your code and push to your repository. This time code deploy should succeed.
