# **Lab 12: AWS Deployment Services**

AWS (Amazon Web Services) offers a wide range of deployment services to
help you launch, manage, and scale applications.

Deploying a **fullstack web app** (frontend + backend + database) and
**AI models** involves multiple components and tools.AWS has many
deployment services. Some of them are

## 1. Amazon Lightsail

- A **simplified VPS (Virtual Private Server)** service.

- Includes everything: compute, networking, and storage bundled.

- Great for small apps, websites, or self-hosted software (e.g.,
  WordPress, Node.js servers).

![](media/media/image1.png){width="6.5in" height="3.4534886264216973in"}

![](media/media/image2.png){width="6.5in" height="3.465115923009624in"}

### Use Cases:

- Small fullstack apps (Node.js, Python, LAMP stack)

- Lightweight ML inference with custom setup (via SSH)

- Static site + backend combo (manual deployment)

### Pros:

- Very easy to use --- minimal AWS knowledge needed

- Fixed, predictable monthly pricing (starts at \$3.50/mo)

- SSH access and pre-configured blueprints (Node.js, WordPress, etc.)

### Cons:

- Limited scalability (no autoscaling)

- Less flexibility compared to EC2 or Fargate

- Not serverless (you manage everything)

### Free Tier:

- **Free for 3 months**: 512 MB RAM + 1 vCPU + 20 GB SSD + 1 TB transfer

## 2. AWS Fargate

- A **serverless container engine** for running Docker containers.

- Works with **ECS** (Elastic Container Service) or **EKS**
  (Kubernetes).

- No need to manage servers or EC2 instances.

> ![](media/media/image3.png){width="6.5in"
> height="3.4647889326334207in"}

###  Use Cases:

- Scalable backend APIs

- Microservices

- AI inference in containerized apps

###  Pros:

- No server management --- autoscaled containers

- Pay only for exact compute/memory used

- Secure by design (isolation per task)

### Cons:

- Slightly complex setup (need to understand ECS/EKS)

- Can be more expensive than EC2 for continuous workloads

### Free Tier:

- **No dedicated Fargate free tier**, but you can use ECS with EC2 in
  the Free Tier.

## 3. AWS Elastic Beanstalk

###  What it is:

- A **PaaS (Platform-as-a-Service)** that handles deployment of full web
  apps.

- Supports Node.js, Python, Java, .NET, Ruby, etc.

- Automatically provisions EC2, load balancer, autoscaling, etc.

![](media/media/image4.png){width="6.5in" height="3.457746062992126in"}

![](media/media/image5.png){width="6.5in" height="3.443662510936133in"}

###  Use Cases:

- Fullstack web apps (Express + React, Django, Flask)

- Auto-scaling REST APIs

###  Pros:

- Easy deployment: just upload code or connect GitHub

- Auto handles infrastructure (EC2, RDS, load balancers)

- Environment configuration via dashboard or CLI

### Cons:

- Less control over infrastructure (some complexity hidden)

- Not suitable for advanced container setups

- Cold starts during updates

### Free Tier:

- You can use **Free Tier EC2 + RDS + S3** resources with Beanstalk.

## 4. AWS Amplify

###  What it is:

- A **fullstack app platform** for **frontend and serverless backend**
  (React, Vue, Angular + GraphQL/REST APIs).

- Focused on modern web and mobile apps.

![](media/media/image6.png){width="6.5in" height="3.436619641294838in"}

###  Use Cases:

- React apps with backend (Auth, API, storage)

- CI/CD for static sites or JAMstack

- Mobile apps with cloud backend

###  Pros:

- Extremely easy Git-based deployment

- Built-in Auth (Cognito), API (AppSync), storage (S3), DB (DynamoDB)

- Auto-scaling and managed hosting

### Cons:

- Geared more toward serverless (not monolithic apps)

- Less flexible than ECS/EC2 for custom servers or models

### Free Tier:

- 1,000 build minutes/month

- 5 GB storage

- 15 GB served/month

## 5. Amazon SageMaker

###  What it is:

- A **complete ML platform** to build, train, and deploy machine
  learning models.

- Supports custom models (PyTorch, TensorFlow, Scikit-learn, etc.)

![](media/media/image7.png){width="6.5in" height="3.654166666666667in"}

###  Use Cases:

- Train and deploy ML models

- Host REST endpoints for AI inference

- Run notebooks for experimentation

###  Pros:

- Fully managed: notebooks, training jobs, endpoints

- Scalable inference (auto-scaling endpoints)

- Model monitoring, versioning, A/B testing

### Cons:

- Pricing can get high for long-term endpoint hosting

- More useful for data scientists than web devs

### Free Tier:

- **For first 2 months** only:

  - 250 hours/month of notebook (ml.t2.medium)

  - 50 training hours

  - 125 hours of hosting endpoint (ml.m4.xlarge)

**[Example Deployment of React App To EC2 instance:]{.underline}**

Ensure Your Application is deployed on github .We will clone the
application from github and serve it with nginx.Add a buildspec.yaml
file to your root directory

![](media/media/image8.png){width="6.5in" height="2.8666666666666667in"}

1.  Launch EC2 instance and login using your Private Key.

2.  Run below commands to install node and npm.

![](media/media/image9.png){width="6.5in" height="3.457746062992126in"}

![](media/media/image10.png){width="6.5in"
height="1.5774650043744531in"}

3.  Now we install git to clone our repository.After that run npm
    install and npm run build to get the production build folder. We
    will use this build folder to serve our application.

![](media/media/image11.png){width="6.5in" height="3.478873578302712in"}

![](media/media/image12.png){width="6.5in" height="3.436619641294838in"}

![](media/media/image13.png){width="6.5in" height="1.901408573928259in"}

4\. Now install nginx to use it to serve our app

![](media/media/image14.png){width="6.5in"
height="3.4718318022747154in"}

![](media/media/image15.png){width="6.4994870953630794in"
height="2.5915496500437447in"}

5.Run sudo nano /etc/nginx/nginx.conf to add the "location /" to serve
the app.

![](media/media/image16.png){width="6.5in" height="3.429577865266842in"}

6\. Restart nginx and use your public ip .

![](media/media/image17.png){width="6.5in" height="3.302817147856518in"}

![](media/media/image18.png){width="6.5in" height="3.359154636920385in"}

7\. If you get nginx internal server error run command "sudo chmod o+x
/home/ec2-user" to give permissions to nginx. Additionally you can run
"sudo tail -n 100 /var/log/nginx/error.log" to get the error trail.

**[Lab Task:]{.underline}**

Simulate deployment of A simple react app using any of amplify , elastic
beanstalk ,lightsail or an ec2 instance.
