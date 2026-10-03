# Week 2: IAM Policies

## S3UploaderOnly-CindyChen

**What it allows:** Uploading objects (s3:PutObject) to my training bucket and downloading objects (s3:GetObject) from it. It does not allow listing buckets, deleting objects, or touching any other bucket.

**Why I scoped it this way:** The user only needs to upload and read files in one place, so the policy grants only those two actions on only the objects in that bucket (the /* at the end of the ARN). Granting less would break the use case, and granting more would give the user access it doesn't need. I confirmed this with `aws s3 ls`, which returned AccessDenied, because listing buckets was never granted.
