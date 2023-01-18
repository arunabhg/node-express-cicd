#!/bin/bash

#give permission for everything in the express-app directory
sudo chmod -R 777 /home/ec2-user/node-express-cicd

#navigate into our working directory where we have all our github files
cd /home/ec2-user/node-express-cicd

echo 'run application_start.sh: ' >> /home/ec2-user/node-express-cicd/deploy.log

#install node modules
npm install

echo 'pm2 start npm start' >> /home/ec2-user/node-express-cicd/deploy.log
sudo pm2 start 'npm start'


# #add npm and node to path
# export NVM_DIR="$HOME/.nvm"	
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # loads nvm	
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # loads nvm bash_completion (node is in path now)



# #start our node app in the background
# node index.js > app.out.log 2> app.err.log < /dev/null & 