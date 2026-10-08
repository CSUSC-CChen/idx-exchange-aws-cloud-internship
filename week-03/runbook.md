# Week 3 Runbook: Deploying PropertyLite to EC2

1. I built a user-data script that installs Python and Flask, writes PropertyLite's app.py and the sample CSV onto the instance, and starts the app on port 8080 when the instance first boots.
2. In EC2 I launched an instance named property-api-01 using Amazon Linux 2023 and a t3.micro, and created a key pair called training-key.
3. I made a security group (launch-wizard-1) that allows SSH on port 22 from my IP only and TCP port 8080 from anywhere, since 8080 is PropertyLite's port.
4. I pasted the user-data script into Advanced details and launched the instance.
5. After about 3 minutes, curl on port 8080 returned {"status":"ok"} for /health and the Sacramento listing for /properties/R100234. See curl-responses.png.
6. I copied the key into ~/.ssh in WSL, set chmod 400 on it, and connected with ssh as ec2-user.
7. I created an EBS snapshot of the root volume. A new volume made from it would be a copy of the disk as of that moment.
8. To clean up I terminated the instance, confirmed the volume was deleted, and deleted the snapshot.
