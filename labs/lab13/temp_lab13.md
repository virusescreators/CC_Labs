# **Lab 13: CI CD with AWS**

CI/CD (Continuous Integration/Continuous Deployment) in AWS is a
practice where code changes are automatically built, tested, and
deployed to your AWS environment with minimal manual intervention. AWS
offers several services that can be combined to create a CI/CD pipeline,
allowing for automation of the entire software delivery process. Here\'s
how you can set it up:

### AWS Services for CI/CD:

1.  **AWS CodeCommit**: A source code repository similar to GitHub,
    where you can store your code.(Unavailable for new users)

2.  **AWS CodeBuild**: A fully managed build service to compile, test,
    and package your application.

3.  **AWS CodeDeploy**: Automates the deployment of applications to a
    variety of compute services such as EC2, Lambda, and ECS.

4.  **AWS CodePipeline**: Orchestrates the flow of your code from source
    to deployment, coordinating CodeCommit, CodeBuild, and CodeDeploy
    into a unified workflow.

# Setting Up The Code Pipeline:

Your Application Must have an appspec.yaml file and a buildspec.yaml
file.They are key to deploying apps using AWS services like CodeDeploy
and CodeBuild.

**buildspec.yaml [--]{.underline}** [Used by AWS CodeBuild]{.underline}

This file tells CodeBuild **how to build your app** (e.g., install
packages, run builds, prepare artifacts).

### Purpose:

- Defines install/build commands

- Prepares output (like built files) as **artifacts**

- These artifacts are later deployed via CodeDeploy

![](labs\lab13/media/image1.png){width="6.5in"
height="2.216666666666667in"}

**appspec.yaml [--]{.underline}** [Used by AWS CodeDeploy]{.underline}

This file **tells CodeDeploy what to do with your files** and when to
run your scripts during deployment.

### Purpose:

- Specifies **where** to copy your app on the EC2 instance

- Defines **lifecycle hooks** like BeforeInstall, AfterInstall,
  ApplicationStart etc.

- Runs custom scripts like restarting NGINX or setting permissions

![](labs\lab13/media/image2.png){width="6.5in"
height="2.316666666666667in"}

Here I use the scripts file to restart the nginx server.

![](labs\lab13/media/image3.png){width="6.5in" height="2.05in"}

**[1.Service Role:]{.underline}**

In IAM create a service role with relevant permissions you will use the
ARN of this policy in codebuild. The permissions in the IAM role depends
on your use case. The role must have atleast permission for codedeploy
and codebuild. In case you want to add logs grant access to s3 bucket
and cloudwatch as well.

**[IAM Role For CodeBuild and CodeDeploy]{.underline}**

![](labs\lab13/media/image4.png){width="6.5in"
height="3.654166666666667in"}

**[IAM Role for CodePipeline:]{.underline}**

![](labs\lab13/media/image5.png){width="6.5in"
height="3.418918416447944in"}

Similiarly create another role for EC2 instance to enable auto code
deployment.

![](labs\lab13/media/image6.png){width="6.5in"
height="3.418918416447944in"}

**[2. Launch an ec2 instance]{.underline}**

Make Sure to Add a tag to your EC2 instance(This step is very
crucial).Run the following commands on it (Remember to change your
region).These commands updates packages and installs the code deploy
agent.We also install nginx to serve our web app.

**sudo yum update -y**

**sudo yum install ruby wget -y**

**cd /home/ec2-user**

**wget
https://aws-codedeploy-ap-northeast-1.s3.amazonaws.com/latest/install**

**chmod +x ./install**

**sudo ./install auto**

**sudo service codedeploy-agent start**

**sudo yum update -y**

**sudo amazon-linux-extras enable nginx1**

**sudo yum install nginx --y**

**sudo nano /etc/nginx/nginx.conf**

and edit the following (change your folder accordingly). Root will point
to folder where your index.html lives.

**server {**

**listen 80;**

**server_name \_;**

**root /home/ec2-user;**

**index index.html;**

**location / {**

**try_files \$uri /index.html;**

**}**

**}**

**[3.Setting up Deployment Group in Codedeploy:]{.underline}**

![](labs\lab13/media/image7.png){width="6.5in"
height="3.4347222222222222in"}

![](labs\lab13/media/image8.png){width="6.5in"
height="3.472972440944882in"}

![](labs\lab13/media/image9.png){width="6.5in"
height="3.47297353455818in"}

**[4.Setting Up CodeDeploy:]{.underline}**

![](labs\lab13/media/image10.png){width="6.5in"
height="3.4756944444444446in"}

![](labs\lab13/media/image11.png){width="6.5in" height="3.34375in"}

**[5. set up the codepipeline]{.underline}**

![](labs\lab13/media/image12.png){width="6.5in" height="3.40625in"}

![](labs\lab13/media/image13.png){width="6.5in"
height="3.4942530621172354in"}

![](labs\lab13/media/image14.png){width="6.5in"
height="3.4712642169728785in"}

![](labs\lab13/media/image15.png){width="6.5in"
height="3.4712642169728785in"}

![](labs\lab13/media/image16.png){width="6.5in"
height="3.4712642169728785in"}

![](labs\lab13/media/image17.png){width="6.5in"
height="3.654166666666667in"}

![](labs\lab13/media/image18.png){width="6.5in"
height="3.4827591863517062in"}

**[Lab Task:]{.underline}**

Set up An AWS code pipeline for an application
