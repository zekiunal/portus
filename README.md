# Portus Install Script

Using S3 for backend storage.

## Create a new bucket for Docker Registry on S3 

    Go to AWS Services -> S3 and create a new bucket (e.g "docker-registry") on your region
    
## Create a user to allow our docker registry to access the new bucket

    Goto AWS Services -> IAM -> Create New Users
    Keep your Access Key and Secret Access Key
    Under the Permission section, click on Attach User Policy.
    
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::docker-registry"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::docker-registry/*"
    }
  ]
}
```

## Create new instance for the registry

## Clone Portus Setup and run script

```
    git clone https://github.com/zekiunal/portus /portus_setup
    cd /portus_setup && chmod +x setup.sh
    ./setup.sh
```

## Setup Screen

```shell
Hostname for your Portus? [registry.domain.com]:
Port for your registry? [5000]:
Your AWS Access Key? [AWS_KEY]:
Your AWS Secret Key? [AWS_SECRET]:
The AWS region in which your bucket exists? [eu-central-1]:
The bucket name in which you want to store the registry's data? [bucket.registry.domain.com]:
SMTP server address? [smtp.domain.com]:
SMTP port? [587]:
SMTP user name? [username]:
SMTP password? [user_password]:

Does this look right?

Hostname          : registry.domain.com
Port              : 5000
AWS Key           : AWS_KEY
AWS Secret        : AWS_SECRET
AWS Region        : eu-central-1
AWS Bucket        : bucket.registry.domain.com
SMTP address      : smtp.domain.com
SMTP port         : 587
SMTP username     : username
SMTP password     : user_password

ENTER to continue, 'n' to try again, Ctrl+C to exit:

```
