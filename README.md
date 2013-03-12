DOCSTORE
========

docstore is a simple Rails application to manage documents stored in Amazon S3
and SimpleDB.

To get up and running, you'll need an AWS account, and you should have the
following environment variables set:

- `AWS_ACCESS_KEY_ID`: your AWS access key
- `AWS_SECRET_ACCESS_KEY`: your AWS secret access key
- `AWS_S3_BUCKET_ID`: name of the S3 bucket you'll be using
- `DOCSTORE_USER`: basic auth username you'll use to log in
- `DOCSTORE_PASS`: basic auth password you'll use to log in
