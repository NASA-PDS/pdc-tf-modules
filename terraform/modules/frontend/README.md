# Create cloudfront distribution for the PDS

## Requirements

To run, this terraform script requires to have components deployed:

- s3 bucket for the s3 browser application
- s3 bucket as a placeholder for the PDS web site
- ALB for the registry API
- a route 53  hosted zone and an SSL certificate
- cache and origin request policies

They are defined in the SSM parameter store as described in the `data.tf` file.

## Run the deployment

From this directory:

    terraform apply
 