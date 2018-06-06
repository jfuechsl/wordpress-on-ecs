# Wordpress on ECS

This small project builds a ready to use Wordpress Docker Image and deploys it on ECS with a MySQL RDS database.

For building the Docker Image it uses:
  1. [HashiCorp Packer](https://www.packer.io/) for building the Docker Image and pushing it to ECR.
  2. [Ansible](https://www.ansible.com/) for provisioning the Docker Image.
  3. [Alpine Linux](https://alpinelinux.org/) as a base Image.
  4. [Docker](https://www.docker.com/) - I think that's self-explanatory

For provisioning the AWS infrastructure [HashiCorp Terraform](https://www.terraform.io/) is used.

## Wordpress Image

Wordpress is run with PHP7 (through php-fpm) and nginx. A one-container approach was chosen, [s6-overlay](https://github.com/just-containers/s6-overlay) is used as the process supervisor for php-fpm and nginx. An alternative approach would be to use different containers for php-fpm and nginx, in which case they would share the web root volume and nginx would also act as reverse-proxy to the php-fpm container via tcp.

To provision the Docker Image with the `ansible` provisioner through Packer the Docker Image needs `python` installed (and the `shadow` package for creating users). Those packages are not installed per default on Alpine Linux, thus before and after the `ansible` provisioner run, a shell provisioner is run which installs, and afterwards removes, the necessary packages.

The nginx and php-fpm worker processes are run as non-root users. Therefore the web root directory must have proper permissions set. This is ensured on container startup by s6-overlay.

For persistence reasons the web root directory is a volume. When the container starts a script checks if the web root volue seems to have a Wordpress installation on it. If not, the Wordpress installation which is bundled with the container is copied over to the volume. In the case the volume already has a Wordpress installation on it, then it is used without changes.

The Wordpress configuration (`wp-config.php`) has been modified to accept environment variables for the most important configuration parameters so it is better suited to run in a containerized environment.

The Packer template makes use of user variables, some of which are expected to be passed to packer through a variables file via the `-var-file` command line flag. An example `variables.json.sample` file is included in the project.

## AWS Infrastructure

The AWS Infrastructure has been kept simple but still realistic. All subnets are public which removes the need for NAT gateways. Security groups have been configured to restrict traffic as much as possible.

RDS is used to provision a MySQL database for Wordpress.

ECS is used to run Docker containers. Container instances are managed inside an Auto-scaling group.
The Wordpress setup is defined through a TaskDefinition and deployed as an ECS service. The web root volume is a basic Docker volume. This is not suited for production use!

Traffic ingress is handled by an Application Load Balancer which forwards to a target group which is associated with the wordpress ECS service.

The Docker Image is stored in an ECR repository. Packer pushes the built Docker images to the repository and Docker engines on the ECS container instances pull it from there.

The awslogs Docker logging driver is used to ship container logs to Cloudwatch.

## Run Instructions

Assuming we have an AWS account and credentials set up via the AWS CLI through a profile.
We further assume that Terraform, Packer, Ansible, and Docker are installed and ready to be used.

### Spin up the AWS Infrastructure
The code is in the folder `aws_infrastructure`, we assume this is the working directory.

1. Create a `secrets.tfvars` file from the `secrets.tfvars.sample` file - fill in viable values (`aws_profile` is the name of the configured profile in the AWS CLI)
2. Review the `configuration.tfvars` file and ensure the values make sense to you.
3. Run `terraform apply -var-file=configuration.tfvars -var-file=secrets.tfvars`
4. Make a note of the output variables, especially the registry url and the ALB dns name.
5. To clean up run `terraform destroy -var-file=configuration.tfvars -var-file=secrets.tfvars`.

### Build and Deploy the Wordpress Docker Image
The code is in the folder `wordpress_image`, we assume this is the working directory.

1. Create a `variables.json` file from the `variables.json.sample` file - fill in the AWS profile and the noted ecr registry url (without the repository name!).
2. Run `packer build -var-file=variables.json wordpress_template.json`
3. Open the noted ALB dns_name in the browser and after some time you should see a Wordpress installation site.

## Problems Along the Way

There were no major problems because information on each component can easily be found on the internet. The biggest challenge was to be able to test quickly during the development of the Docker Image and the AWS Infrastructure. Building a Docker Image takes some time (not that much) so the feeback loop takes minutes, not seconds. The same thing is true for the AWS infrastructure.
For debugging issues on AWS it was necessary to deploy SSH keys on the instances and allow SSH traffic. Another helpful tool for debugging AWS infrastructure issues was to use the `-target` flag in the Terraform CLI. It allows to limit operations to isolated resources (and their dependencies) of the infrastructure.

## Possible Improvements

Where to start? :-))

The current setup uses plain Docker volumes for the web root volume. This is BAD. Whenever the Wordpress container is moved to a different instance (or otherwise deleted) the Wordpress files (`wp-content` and other modifications) are lost. The data on the DB would still be in place which would effectively render the Wordpress site corrupted. It also limits the deployment to exactly one Wordpress container - no horizontal scaling. A way to fix this is to use a shared file-system (such as EFS) and create a host mounted volume for the web root. I don't know exactly if Wordpress itself works well in such a setting, but it is a direction that I think can be explored. On top of that, file-system backups can and should be implemented as well.

Another improvement concerns the RDS database. For a production scenario it should be configured as a multi-AZ instance with provisioned IOPS, defined backup- and maintenance-windows, and possibly read-replicas. Maybe using Aurora instead of MySQL would be a further improvement, but it would have to be thoroughly tested to spark enough confidence for a production deployment.

In production it is of utmost importance to have full visibility into the system. This means that logs must be easily accessible and centrally managed. Important metrics need to be collected, processed, and visualized. I would start with metrics concerning the infrastructure but also aim to cover application centric metrics.

The configuration of nginx and PHP is currently very simple. It should be tweaked and optimized for production use.

Wordpress configuration can be optimized as well, especially sessions should be stored in the DB.

Another Wordpress related improvement is to configure caching and provision a caching service such as ElastiCache. Another optimization is to use a CDN such as CloudFront to serve static assets.

The current setup does not use HTTPS, this must be changed - at least configure SSL certificates on the ALB with the AWS Certificate Manager.

Depending on how much the traffic to the Wordpress site varies automatic scaling of the wordpress ECS service and of the ECS cluster instances as a whole should be set up. Either a time- or metrics-based scaling schedule is possible. When scaling based on metrics, make sure to be able to absorb initial load spikes before new instances are provisioned and ready to serve traffic.

Currently all sensitive information is passed to Wordpress through environment variables. This is a big security concern. it would be best to deploy a secrets management solution such as [HashiCorp Vault](https://www.vaultproject.io/) and use that.

When multiple developer work on the infrastructure, managing the Terraform state file quickly becomes a challenge. This can be improved. Remember: the state file can contain potentially sensitive information, do not check it in to your repository. If you do, at least encrypt it.

### How to get it to Production

To move to a production environment with confidence I suggest to tackle all of the improvements above.
The most important are:
1. Web root file system + backups
2. SSL
3. Production-ready RDS database
4. Production-ready PHP & nginx configuration
5. Production-ready instance types for the container instances
6. Wordpress optimization, caching, and CDN
7. Logs management and monitoring
8. Auto-scaling
9. Secrets management
10. Terraform state management
