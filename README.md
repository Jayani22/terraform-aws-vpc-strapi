### Strapi Deployment on AWS using Terraform & Docker ###

1. Created a custom VPC using Terraform with public and private subnets.

2. Added an Internet Gateway for public access and a NAT Gateway so the private EC2 can access the internet.

3. Launched a private EC2 instance (no public IP) to run the Strapi application.

4. Created an Application Load Balancer in the public subnet to access the app securely.

5. Dockerized the Strapi application and stored the image in Amazon ECR.

6. Used GitHub Actions to build the Docker image to avoid EC2 memory issues.

7. Configured EC2 to pull and run the Docker image automatically using user_data.

8. Passed required Strapi production secrets as environment variables.

9. Verified the setup using ALB DNS and checked container health.