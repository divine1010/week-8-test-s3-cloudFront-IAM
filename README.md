# week-8-test-s3-cloudFront-IAM

url:  https://my-devops-internship-bucket-dinesh.mounickraj.com

1) Create a terraform script to configure s3 bucket to host a static website & cloudFront to get Https state & create IAM roles for cloudFront&s3 and EC2 named main.tf

2) Create Index.html and error.html pages for satic website configuration in s3.

3) create a s3 bucket for "my-devops-intership-bucket-dinesh" and "my-log-bucket-dinesh"

4) configure terraform "my-devops-intership-bucket-dinesh" bucket to enable versioning and logging to bucket "my-log-bucket-dinesh"

5) Configure terraform script to provide public access to both buckets and set policies to enable static website hosting in bucket "my-devops-intership-bucket-dinesh" and put log in "my-log-bucket-dinesh"

6) Configure terraform to get certicate for the domain named "my-devops-intership-bucket-dinesh.mounickraj.com"

7) Configure terraform to create cloudfront distributions to the endpoint of the bucket "my-devops-intership-bucket-dinesh" and set viewer-protocol-policy to https

8) Configure terraform script to create IAM roles for cloudfront & s3 and EC2.
