# Create cloudfront distribution for the PDS

## Requirements

To run, this terraform script requires to have components deployed:

- s3 bucket for the s3 browser application
- s3 bucket for the portal-wp application
- s3 bucket as a placeholder for the PDS web site
- ALB for the registry API
- a route 53  hosted zone and an SSL certificate
- cache and origin request policies

They are defined in the SSM parameter store as described in the `data.tf` file.

## Run the deployment

From this directory:

    terraform init
    terraform apply


## Validate the deployment

From the hosted zone defined in route 53, e.g. pds.nasa.gov

You can test:
1. access to the registry API:
    curl --header 'application/json' https://pds.nasa.gov/api/search/1/products

2. access to the S3 browser, in a web browser: https://pds.nasa.gov/data
3. access to the Data Upload Manager API: To Be Defined
4. access to the PDS Web site placeholder: http://pds.nasa.gov
 