# aws-alchemy

Here's my sample Terraform IaC deployment using Elastic Beanstalk.  
Due to time constraints, not everything was completed. What is and isn't done is described bleow.

Deployment is simple: ensure your environment is set up for AWS with the proper permissions - 
AdministratorAccess-AWSElasticBeanstalk _should_ be all you need, but I performed this test using the 
Admin account in my free tier AWS environment. Navigating to Elastic Beanstalk will give you the URLs of 
the applications it created, since they depend on the CNAME of the load balancer created. 

Otherwise, `terraform init` -> `terraform plan` -> `terraform apply` should deploy everything automatically.


- It deploys a simple Flask "Hello World!" application  
- There are two environments it creates - a production environment that uses t3.small instances and 
a staging environment that uses t3.micro instances  
- Thanks to Elastic Beanstalk, this is both Auto-scaled and Load Balanced by default
- A Cloudwatch alarm is set up to trigger when CPU usuage goes above 75%, and sends a message off to an 
SNS topic that my email is subscribed to.  
- HTTPS is _not_ enabled. I was able to figure out how to generate my certificate, upload it to AWS, and
add it to my load balancer to accept HTTPS traffic over port 443 and simlutaneously disable traffic to HTTP 
on port 80, but not how to do all of this in an IaC deployment. A day later, I think I have some more ideas
to try, but that will be left for my own free time.  
- This does not deploy through Jenkins or any other CI/CD solution currently due to running out of the time 
I alloted myself. I figured I would do that at the end of my process, but I had trouble doing certain aspects 
of my Terraform code.

Automation of code updates in this case would be relatively simple. Have a hook into your repository to watch for code 
deployments, attempt to build a new version of your code, and if the build succeeds deploy it to a new instance 
using a Blue-Green deployment strategy. After the new instance is up and running, ensure that the environment is 
running correctly. If everything looks good, switch traffic from the old deployment to the new deployment 
via your load balancer.