# **Lab 9: Load Balancers and Target Groups**

A load balancer is a device or software application that distributes
incoming network traffic across multiple servers to improve application
performance, reliability, and availability. It acts as a traffic
director, routing client requests to available servers in a server farm
or pool, preventing any single server from being overloaded.

A Target Group is a collection of one or more instances, IP addresses,
or Lambda functions that receive traffic from a load balancer. They act
as the destination for traffic routed by load balancer rules, allowing
for efficient management and distribution of traffic to various backend
resources. 

**[Steps To Create a Load Balancer:]{.underline}**

To Add Load Balancer to Our EC2 instances we launch 2 instances and
configure them accordingly

1.  Go to AWS EC2 instance dashboard and launch two instances in same
    VPC but different subnets.

2.  Add rule for http and ssh in security group setting.

3.  Launch Your instances.

4.  Connect with putty to your instances and run following commands in
    case your zip website is in an s3 bucket .

![](media/image1.png){width="6.5in" height="3.4943821084864393in"}

5.  After zipping copy the files to html folder. This should ensure your
    ec2 instance serves your website now.

![](media/image2.png){width="6.5in" height="3.471910542432196in"}

6.  Create Target Group for load Balancer.Set target type as Instance
    and for health check part add index.html which is the root path.Add
    your EC2 instances to registered target.

7.  Now create Application Load Balancer to attach t­­o your target
    group.It should be internet facing and it should listen on port 80
    for http.

> ![](media/image3.png){width="6.5in" height="3.4494378827646544in"}

8.  In Load balancer settings select the availability zone where your
    ec2 instances are launched

![](media/image4.png){width="6.5in" height="3.4943821084864393in"}

9.  Create a security group with port 80 access on Load Balancer.

![](media/image5.png){width="6.5in" height="3.4943821084864393in"}

10. After creating the Security group in routing forward requests on
    port 80 to your new target group.

11. Check your target group now your instances should be healthy now.

12. Copy the ELB DNS and paste in browser and you should be able to see
    your application now

![](media/image6.png){width="6.5in" height="3.483146325459318in"}

![](media/image7.png){width="6.5in" height="3.4943821084864393in"}

**[Lab Tasks:]{.underline}**

1.  Create Your Own VPC network in any availability zone .

2.  Create a minimum of 2 private subnets and launch EC2 instances.

3.  Deploy any static website to your EC2 instance.

4.  Attach Load Balancer and create a target group. Ensure your
    application is only accessible through the load balancer.
