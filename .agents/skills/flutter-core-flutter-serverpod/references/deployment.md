# Deploying Serverpod to Production

Complete guide to deploying Serverpod applications to production including Docker containerization, AWS deployment with Terraform, Google Cloud Platform, server configuration, and monitoring.

## Production Preparation

Essential steps before deploying to production.

### Environment Configuration

Create production configuration file:

```yaml
# config/production.yaml
apiServer:
  port: 8080
  publicHost: api.yourdomain.com
  publicPort: 443
  publicScheme: https

insights:
  port: 8081
  publicHost: insights.yourdomain.com
  publicPort: 443
  publicScheme: https

database:
  host: your-db-host.region.rds.amazonaws.com
  port: 5432
  name: production_db
  user: production_user

redis:
  enabled: true
  host: your-redis-host.region.cache.amazonaws.com
  port: 6379

storage:
  s3:
    bucket: your-production-bucket
    region: us-east-1
    publicHost: your-bucket.s3.amazonaws.com
```

### Secrets Management

Store production secrets securely:

```yaml
# config/passwords.yaml (DO NOT COMMIT)
production:
  database: 'secure_database_password'
  jwtRefreshTokenHashPepper: 'your_32_byte_minimum_pepper'
  jwtHmacSha512PrivateKey: 'your_hmac_secret_key'
  s3AccessKeyId: 'YOUR_AWS_ACCESS_KEY'
  s3SecretAccessKey: 'YOUR_AWS_SECRET_KEY'
  googleIdpClientId: 'production_client_id'
  googleIdpClientSecret: 'production_client_secret'
```

**Environment Variables Alternative**:

```bash
# Preferred for production
export SERVERPOD_PASSWORD_DATABASE='secure_password'
export SERVERPOD_PASSWORD_JWT_REFRESH_TOKEN_HASH_PEPPER='pepper'
export SERVERPOD_PASSWORD_JWT_HMAC_SHA512_PRIVATE_KEY='key'
export SERVERPOD_PASSWORD_S3_ACCESS_KEY_ID='key_id'
export SERVERPOD_PASSWORD_S3_SECRET_ACCESS_KEY='secret'
```

### Code Preparation

Ensure code is production-ready:

**Generate Production Code**:
```bash
cd my_app_server
serverpod generate
```

**Run Tests**:
```bash
dart test
```

**Create Database Migration**:
```bash
serverpod create-migration --tag "production-v1"
```

## Docker Deployment

Containerize your Serverpod application for deployment.

### Dockerfile

Serverpod projects include a generated Dockerfile:

```dockerfile
# my_app_server/Dockerfile
FROM dart:3.2 AS build

WORKDIR /app
COPY . .

RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/
COPY --from=build /app/config/ /app/config/
COPY --from=build /app/migrations/ /app/migrations/

EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Default to production mode
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

WORKDIR /app
CMD bin/server \
  --mode ${runmode} \
  --server-id ${serverid} \
  --logging ${logging} \
  --role ${role} \
  --apply-migrations
```

### Building Docker Image

Build the image:

```bash
cd my_app_server

# Build with tag
docker build -t my-app-server:latest .

# Build with version tag
docker build -t my-app-server:1.0.0 .
```

### Running Locally with Docker

Test the container locally:

```bash
# Run with environment variables
docker run -d \
  --name my-app-server \
  -p 8080:8080 \
  -p 8081:8081 \
  -e runmode=production \
  -e SERVERPOD_PASSWORD_DATABASE='db_password' \
  my-app-server:latest
```

### Docker Compose for Local Testing

Create `docker-compose.production.yaml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: production_db
      POSTGRES_USER: production_user
      POSTGRES_PASSWORD: production_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  server:
    build: .
    depends_on:
      - postgres
      - redis
    environment:
      runmode: production
      SERVERPOD_PASSWORD_DATABASE: 'production_password'
    ports:
      - "8080:8080"
      - "8081:8081"

volumes:
  postgres_data:
```

Run:

```bash
docker-compose -f docker-compose.production.yaml up
```

## AWS Deployment with Terraform

Deploy to AWS using provided Terraform scripts.

### Prerequisites

**Install Required Tools**:
- AWS CLI: `brew install awscli` (macOS) or download from aws.amazon.com
- Terraform: `brew install terraform` or download from terraform.io

**AWS Account Setup**:
- Create AWS account (allow 24 hours for activation)
- Configure credentials: `aws configure`

**GitHub Setup**:
- Push project to GitHub repository
- Serverpod project must be at repository root

### Domain and SSL Setup

**Route 53 Hosted Zone**:
1. Open Route 53 in AWS Console
2. Create hosted zone for your domain (e.g., `yourdomain.com`)
3. Update domain nameservers to AWS nameservers
4. Note the hosted zone ID

**SSL Certificates**:

Create certificates in AWS Certificate Manager:

1. **API Certificate** (us-west-2 or your region):
   - Request wildcard certificate: `*.yourdomain.com`
   - DNS validation (automatic if using Route 53)
   - Note the ARN

2. **CloudFront Certificate** (us-east-1 required):
   - Switch to us-east-1 region
   - Request same wildcard certificate: `*.yourdomain.com`
   - DNS validation
   - Note the ARN

### Terraform Configuration

Edit `my_app_server/deploy/aws/terraform/config.auto.tfvars`:

```hcl
# Your project name
project = "myapp"

# Hosted zone
hosted_zone_id = "Z1234567890ABC"
top_domain = "yourdomain.com"

# SSL certificates
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/abc-def-ghi"
cloudfront_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/def-ghi-jkl"

# Server configuration
instance_type = "t3.small"  # Or t3.medium for production
min_servers = 2
max_servers = 10

# Database
database_instance_class = "db.t3.small"  # Or db.t3.medium
database_allocated_storage = 20  # GB
database_backup_retention_days = 7
```

### GitHub Secrets

Add secrets to GitHub repository (Settings > Secrets > Actions):

**AWS_ACCESS_KEY_ID**: Your AWS access key

**AWS_SECRET_ACCESS_KEY**: Your AWS secret key

**SERVERPOD_PASSWORDS**: Contents of `config/passwords.yaml` for production

```yaml
# SERVERPOD_PASSWORDS secret value
production:
  database: 'your_secure_db_password'
  jwtRefreshTokenHashPepper: 'your_secure_pepper'
  jwtHmacSha512PrivateKey: 'your_hmac_key'
  # ... other secrets
```

### Dart Version Configuration

Ensure matching Dart versions:

**.github/workflows/deployment-aws.yml**:
```yaml
- name: Setup Dart
  uses: dart-lang/setup-dart@v1
  with:
    sdk: 3.2.0  # Match this version
```

**deploy/aws/scripts/install_dependencies**:
```bash
DART_VERSION="3.2.0"  # Match this version
```

### Initialize Infrastructure

Run Terraform to create AWS resources:

```bash
cd my_app_server/deploy/aws/terraform

# Set database password (don't store in files)
export TF_VAR_DATABASE_PASSWORD_PRODUCTION='your_secure_password'

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Create infrastructure
terraform apply
```

This creates:
- Autoscaling EC2 cluster
- Application Load Balancer
- RDS PostgreSQL database
- ElastiCache Redis instance
- S3 buckets for file storage
- CloudFront distribution
- Route 53 DNS records
- Security groups and IAM roles

**Deployment URLs** (after completion):
- API: `https://api.yourdomain.com`
- Web app: `https://app.yourdomain.com`
- Insights: `https://insights.yourdomain.com`
- Database: `database.yourdomain.com:5432`
- Storage: `https://storage.yourdomain.com`

### Deploy Code

Deploy via GitHub Actions:

**Method 1: Push to deployment branch**
```bash
git push origin main:deployment-aws-production
```

**Method 2: Manual trigger**
1. Go to GitHub repository
2. Click Actions tab
3. Select "Deploy to AWS Production"
4. Click "Run workflow"

GitHub Actions will:
1. Build Docker image
2. Push to Amazon ECR
3. Deploy to EC2 instances via CodeDeploy
4. Apply database migrations
5. Perform health checks

### Database Migration

Apply migrations to production database:

**Option 1: Via deployment**
Migrations apply automatically with `--apply-migrations` flag in Dockerfile CMD.

**Option 2: Manual migration**
```bash
# Connect to an EC2 instance
aws ssm start-session --target i-1234567890abcdef

# Navigate to app directory
cd /srv/serverpod

# Run migration
./bin/server --role maintenance --apply-migrations --mode production
```

**Option 3: From local machine**
```bash
# Connect to production database
export DATABASE_HOST='database.yourdomain.com'
export DATABASE_PASSWORD='your_password'

# Run migration
cd my_app_server
dart run bin/main.dart \
  --mode production \
  --role maintenance \
  --apply-migrations
```

## Google Cloud Platform Deployment

Deploy to GCP using Terraform.

### GCP Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed: `brew install google-cloud-sdk`
- Terraform installed

### GCP Terraform Configuration

Edit `my_app_server/deploy/gcp/terraform/config.auto.tfvars`:

```hcl
project_id = "your-gcp-project-id"
region = "us-central1"
zone = "us-central1-a"

# Domain configuration
domain = "yourdomain.com"

# Server configuration
instance_type = "e2-small"
min_instances = 2
max_instances = 10

# Database
database_tier = "db-g1-small"
database_disk_size = 20
```

### Deploy to GCP

```bash
cd my_app_server/deploy/gcp/terraform

export TF_VAR_DATABASE_PASSWORD='your_password'

terraform init
terraform plan
terraform apply
```

## Server Roles

Serverpod supports three server roles for different deployment scenarios.

### Monolith (Default)

Handles both incoming requests and maintenance tasks:

```bash
dart run bin/main.dart --role monolith
```

**Use When**:
- Single server deployments
- Small to medium scale
- Clustered deployments where all servers are identical

### Serverless

Handles only incoming connections, no maintenance tasks:

```bash
dart run bin/main.dart --role serverless
```

**Use When**:
- Serverless platforms (AWS Lambda, Cloud Run)
- Autoscaling environments where instances come and go
- Maintenance tasks run on separate schedule (cron jobs)

**Requirements**:
- External cron jobs for maintenance
- Separate process for scheduled tasks

### Maintenance

Runs maintenance tasks once then exits:

```bash
dart run bin/main.dart --role maintenance --apply-migrations
```

**Use For**:
- Applying database migrations in CI/CD
- Running scheduled maintenance
- One-time administrative tasks

## Monitoring and Logging

Monitor production deployments.

### Serverpod Insights

Connect to production server:

1. Open Serverpod Insights app
2. Add new connection:
   - **Name**: Production
   - **Host**: insights.yourdomain.com
   - **Port**: 443
   - **Use SSL**: Yes
   - **Password**: (if configured)

**Features**:
- Real-time log viewing
- Database query monitoring
- Performance metrics
- Error tracking

### CloudWatch Logs (AWS)

View application logs:

```bash
# View logs for log group
aws logs tail /aws/ec2/serverpod --follow

# Filter by error level
aws logs filter-log-events \
  --log-group-name /aws/ec2/serverpod \
  --filter-pattern "ERROR"
```

### Custom Logging

Configure application logging:

```dart
// lib/server.dart
void run(List<String> args) async {
  var pod = Serverpod(args, Protocol(), Endpoints());

  // Configure logging
  pod.logger.level = LogLevel.info;

  // Add custom log handler
  pod.logger.addHandler((logEntry) {
    // Send to external service (Sentry, Datadog, etc.)
    if (logEntry.level == LogLevel.error) {
      sendToErrorTracking(logEntry);
    }
  });

  await pod.start();
}
```

### Health Checks

Implement health check endpoint:

```dart
// lib/src/endpoints/health_endpoint.dart
class HealthEndpoint extends Endpoint {
  Future<HealthStatus> check(Session session) async {
    // Check database connectivity
    try {
      await session.db.query('SELECT 1');
    } catch (e) {
      return HealthStatus(
        status: 'unhealthy',
        database: false,
        error: e.toString(),
      );
    }

    // Check Redis (if enabled)
    var redisOk = true;
    if (session.serverpod.redis.enabled) {
      try {
        await session.serverpod.redis.ping();
      } catch (e) {
        redisOk = false;
      }
    }

    return HealthStatus(
      status: redisOk ? 'healthy' : 'degraded',
      database: true,
      redis: redisOk,
    );
  }
}
```

**Load Balancer Health Check**:
Configure ALB to query `/health` endpoint.

## Scaling Considerations

### Horizontal Scaling

AWS Terraform configuration includes autoscaling:

```hcl
# Scales based on CPU utilization
resource "aws_autoscaling_policy" "scale_up" {
  name = "scale-up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}
```

**Adjust Scaling**:
Modify `min_servers` and `max_servers` in `config.auto.tfvars`.

### Database Scaling

**Vertical Scaling**:
Increase database instance size:

```hcl
database_instance_class = "db.t3.medium"  # or db.t3.large
```

**Read Replicas**:
Create read replicas for read-heavy workloads:

```hcl
resource "aws_db_instance" "read_replica" {
  replicate_source_db = aws_db_instance.postgres.id
  instance_class = "db.t3.small"
}
```

Configure in application:
```yaml
database:
  host: primary-db-host.rds.amazonaws.com
  read_replicas:
    - replica1-db-host.rds.amazonaws.com
    - replica2-db-host.rds.amazonaws.com
```

### Redis Scaling

Enable Redis for distributed caching:

```yaml
# config/production.yaml
redis:
  enabled: true
  host: production-redis.cache.amazonaws.com
  port: 6379
```

Use cluster mode for high availability:

```hcl
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "serverpod-redis"
  engine = "redis"
  node_type = "cache.t3.micro"
  num_cache_clusters = 2
  automatic_failover_enabled = true
}
```

## Backup and Recovery

### Database Backups

**Automated Backups** (AWS RDS):

```hcl
database_backup_retention_days = 7  # Keep 7 days of backups
```

**Manual Snapshot**:
```bash
aws rds create-db-snapshot \
  --db-instance-identifier production-db \
  --db-snapshot-identifier manual-backup-2024-01-15
```

**Restore from Snapshot**:
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db \
  --db-snapshot-identifier manual-backup-2024-01-15
```

### Migration Files Backup

Commit migration files to version control:

```bash
git add migrations/
git commit -m "Add production migration v1.2.0"
git push
```

Store definition SQL separately:

```bash
# Export schema
pg_dump --schema-only production_db > schema_backup_2024-01-15.sql
```

## Troubleshooting

### Connection Issues

**Check server status**:
```bash
# AWS
aws ec2 describe-instances --filters "Name=tag:Name,Values=serverpod-server"

# SSH to instance
aws ssm start-session --target i-1234567890abcdef
```

**Check server logs**:
```bash
# On EC2 instance
sudo journalctl -u serverpod -f

# Application logs
tail -f /var/log/serverpod/server.log
```

### Migration Failures

**View migration status**:
```bash
# Connect to database
psql -h database.yourdomain.com -U postgres production_db

# Check migration table
SELECT * FROM serverpod_migrations ORDER BY timestamp DESC;
```

**Rollback migration**:
```bash
# Create repair migration to previous version
serverpod create-repair-migration --version 20240101000000000 --mode production

# Apply repair migration
dart run bin/main.dart --role maintenance --apply-migrations --mode production
```

### Performance Issues

**Identify slow queries**:

Query Serverpod logs:
```sql
SELECT * FROM serverpod_query_log
WHERE duration > 1000  -- Queries slower than 1 second
ORDER BY timestamp DESC
LIMIT 100;
```

**Database performance**:
```sql
-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

Serverpod's deployment flexibility supports everything from simple VPS hosting to enterprise-scale AWS deployments with autoscaling, monitoring, and high availability.
