# 🌤️ Weather App — Terraform Infrastructure

Terraform project that provisions the complete serverless AWS infrastructure for a weather web application. The app delivers real-time weather data via the OpenWeatherMap API and is hosted entirely on managed AWS services — no EC2, no containers, no servers to patch.

> **Companion article:** [Automating a Serverless AWS Weather App with Terraform](https://medium.com) · [Original architecture deep-dive](https://medium.com)

---

## Architecture

```
User → Route 53 (CNAME) → CloudFront (WAF + ACM TLS) → S3 (index.html)
                                     ↓
                              API Gateway (REST)
                                     ↓
                              Lambda (Python 3.11)
                                     ↓
                         Secrets Manager → OpenWeatherMap API
```

| Layer | Service | Purpose |
|-------|---------|---------|
| DNS | Amazon Route 53 | CNAME record → CloudFront distribution |
| TLS | AWS Certificate Manager | HTTPS certificate (provisioned in `us-east-1`) |
| CDN | Amazon CloudFront | Edge caching, HTTP→HTTPS redirect, OAC |
| Frontend | Amazon S3 | Private static hosting for `index.html` |
| API | Amazon API Gateway | REST endpoint, Lambda Proxy integration |
| Compute | AWS Lambda | Python business logic, weather data fetching |
| Secrets | AWS Secrets Manager | OpenWeatherMap API key at runtime |

---

## Project Structure

```
weather-app/
├── main.tf               # Root module — composes all modules
├── provider.tf           # AWS provider config + S3 remote state backend
├── output.tf             # Root outputs (API Gateway invocation URL)
└── modules/
    ├── acm/              # TLS certificate + Route 53 DNS validation
    │   ├── main.tf
    │   ├── data.tf
    │   ├── var.tf
    │   └── output.tf
    ├── cloudfront/       # CloudFront distribution + Origin Access Control
    │   ├── main.tf
    │   ├── data.tf
    │   ├── var.tf
    │   └── output.tf
    ├── dns/              # Route 53 CNAME record
    │   ├── main.tf
    │   ├── var.tf
    │   └── output.tf
    ├── gateway/          # API Gateway REST API, resource, method, stage
    │   ├── main.tf
    │   ├── variable.tf
    │   └── output.tf
    ├── lambda/           # Lambda function, IAM role, Secrets Manager policy
    │   ├── main.tf
    │   ├── data.tf
    │   ├── variable.tf
    │   ├── output.tf
    │   └── function.zip  # Deployment package (Python 3.11)
    └── s3/               # S3 bucket, public access block, bucket policy, index.html upload
        ├── main.tf
        ├── data.tf
        ├── var.tf
        ├── output.tf
        └── index.html
```

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.10 |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | >= 2.x |
| AWS credentials | Configured via `aws configure` or environment variables |

Your AWS credentials must have permissions to create and manage: S3, CloudFront, ACM, Route 53, API Gateway, Lambda, IAM, and Secrets Manager resources.

---

## Remote State Backend

This project uses an S3 bucket for remote state storage with native S3 locking (Terraform >= 1.10 — no DynamoDB table required).

Before running `terraform init`, create the state bucket in `eu-west-2`:

```bash
aws s3api create-bucket \
  --bucket terrafrom-weather-app-backend \
  --region eu-west-2 \
  --create-bucket-configuration LocationConstraint=eu-west-2

aws s3api put-bucket-encryption \
  --bucket terrafrom-weather-app-backend \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

---

## Configuration

Before deploying, update the following values in `main.tf` to match your environment:

| Variable | Location | Description |
|----------|----------|-------------|
| `cloudfront_alternate_domain` | `module.cloudfront` | Your app's custom domain (e.g. `weatherapp.example.com`) |
| `domain_name` | `module.weatherapp_certificate` | Same as above — domain for the ACM certificate |
| `hosted_zone` | `module.weatherapp_dns` | Your Route 53 hosted zone root (e.g. `example.com`) |
| `weatherapp_record` | `module.weatherapp_dns` | The full CNAME record to create |

Also update the hardcoded hosted zone ID (`Z04014681W7MWNSSOUZXJ`) in `modules/dns/main.tf` and `modules/acm/data.tf` to your own Route 53 hosted zone ID.

> **Secrets Manager:** The Lambda function expects a secret named `weatherapp/apikey` with a key of `api_key`. Create this before deploying:
> ```bash
> aws secretsmanager create-secret \
>   --name weatherapp/apikey \
>   --secret-string '{"api_key":"YOUR_OPENWEATHERMAP_KEY"}' \
>   --region eu-west-2
> ```

---

## Deployment

```bash
# 1. Initialise — downloads providers and configures the S3 backend
terraform init

# 2. Preview — shows all resources that will be created
terraform plan

# 3. Deploy — provisions the full stack (~5–10 min, ACM validation is the bottleneck)
terraform apply
```

On completion, Terraform prints the API Gateway invocation URL:

```
Outputs:

gateway_invocation_url = "https://<id>.execute-api.eu-west-2.amazonaws.com/prod"
```

---

## Teardown

```bash
terraform destroy
```

The S3 bucket is created with `force_destroy = true`, so Terraform will empty and delete it automatically. All other resources are fully removed by `destroy`.

---

## Module Reference

### `acm`
Provisions an ACM certificate in `us-east-1` (required for CloudFront) using DNS validation. Automatically creates the required CNAME records in Route 53 and waits for full certificate issuance before outputting the ARN.

| Input | Type | Description |
|-------|------|-------------|
| `domain_name` | `string` | Domain to issue the certificate for |

| Output | Description |
|--------|-------------|
| `cert_validation_arn` | ARN of the validated certificate (safe to attach to CloudFront) |

---

### `cloudfront`
Creates a CloudFront distribution with Origin Access Control (OAC/SigV4), HTTP→HTTPS redirect, and a custom domain backed by the ACM certificate.

| Input | Type | Description |
|-------|------|-------------|
| `s3_domain_name` | `string` | Regional domain name of the S3 origin bucket |
| `cloudfront_alternate_domain` | `string` | Custom domain alias for the distribution |
| `aws_acm_certificate_validation_arn` | `string` | Validated ACM certificate ARN |

| Output | Description |
|--------|-------------|
| `cloudfront_domain_name` | CloudFront distribution domain (target for Route 53 CNAME) |
| `cloudfront_domain_arn` | Distribution ARN (used to scope the S3 bucket policy) |

---

### `s3`
Creates a private S3 bucket with all public access blocked, uploads `index.html`, and applies a bucket policy granting read access exclusively to the CloudFront distribution via service principal condition.

| Input | Type | Description |
|-------|------|-------------|
| `bucket_name` | `string` | Project tag name for the bucket |
| `cloudfront_domain_arn` | `string` | CloudFront distribution ARN for the bucket policy condition |

| Output | Description |
|--------|-------------|
| `bucket_domain_name` | Regional domain name (passed to CloudFront as origin) |

---

### `gateway`
Provisions a REST API with a single resource, `ANY` method, and Lambda Proxy integration. Creates a deployment and `prod` stage.

| Input | Type | Description |
|-------|------|-------------|
| `lambda_invoke_arn` | `string` | Lambda function invoke ARN for the integration URI |

| Output | Description |
|--------|-------------|
| `gateway_execution_arn` | Execution ARN used to scope the Lambda permission |
| `gateway_invocation_url` | Full invocation URL including stage |

---

### `lambda`
Deploys the Python 3.11 Lambda function from `function.zip`, creates an IAM execution role with a Secrets Manager policy, and grants API Gateway permission to invoke the function.

| Input | Type | Description |
|-------|------|-------------|
| `gateway_execution_arn` | `string` | API Gateway execution ARN for the `aws_lambda_permission` |

| Output | Description |
|--------|-------------|
| `lambda_invoke_arn` | Invoke ARN passed to the API Gateway integration |

---

### `dns`
Creates a Route 53 CNAME record pointing the custom app domain at the CloudFront distribution.

| Input | Type | Description |
|-------|------|-------------|
| `hosted_zone` | `string` | Root hosted zone name |
| `weatherapp_record` | `string` | FQDN of the CNAME record to create |
| `weatherapp_ttl` | `number` | TTL in seconds (60 recommended) |
| `weatherapp_value` | `list(string)` | CloudFront distribution domain name |

---

## Known Limitations & Improvements

- **IAM policy scope** — The Secrets Manager policy in the Lambda module uses `Resource = "*"`. For production, this should be tightened to the specific secret ARN.
- **Hardcoded hosted zone ID** — The Route 53 zone ID appears directly in `modules/dns/main.tf` and `modules/acm/data.tf`. Refactoring to a variable or data source lookup would make the modules portable across accounts.
- **WAF not yet in Terraform** — The manually configured WAF web ACL (protecting against SQLi, XSS, and rate abuse) is not yet represented as a module. Adding `aws_wafv2_web_acl` and associating it with the CloudFront distribution is the recommended next step.
- **Lambda memory/timeout not variable** — Currently defaults to 128 MB / 3s. Exposing these as module variables would allow environment-specific tuning.

---

## License

MIT