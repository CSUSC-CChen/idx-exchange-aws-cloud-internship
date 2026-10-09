# Week 4: Storage and Database Decision Guide

| Service | Use this when... |
|---|---|
| S3 | You need cheap, durable object storage for files like backups, logs, images, or static assets. |
| EBS | One EC2 instance needs a fast disk for its operating system or a database. |
| EFS | Several instances need to read and write the same files at the same time. |
| RDS | Your data has tables and relationships and you need SQL, joins, and transactions. |
| DynamoDB | You need very fast lookups by key at any scale with no servers to manage. |
