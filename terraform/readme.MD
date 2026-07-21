# Terraform: 5 EC2 Instances (prometheus, node-1, node-2, elk, frontend)

## What this creates
| Name | Instance type | Tags | IAM instance profile |
|---|---|---|---|
| **prometheus** | `t3.medium` | — | ✅ attached |
| **node-1** | `t3.micro` | `Monitoring = true` | — |
| **node-2** | `t3.micro` | `Monitoring = true` | — |
| **elk** | `t3.medium` | — | — |
| **frontend** | `t3.micro` | — | — |

All instances:
- Use the same AMI ID (`var.ami_id`)
- Launch with **no key pair** (`key_name = null`)
- Attach your **custom security groups** (`var.security_group_ids`)

Sizing and tagging are driven by simple conditional logic in `main.tf`,
looping over the `instance_names` list:

```hcl
instance_type = contains(["prometheus", "elk"], each.key) ? "t3.medium" : "t3.micro"

tags = merge(
  { Name = each.key },
  contains(["node-1", "node-2"], each.key) ? { Monitoring = "true" } : {}
)
```

## Important note on IAM
EC2 instances attach to an **instance profile**, not a role directly. If you
already have an instance profile (e.g. one created via the console, such as
`PrometheusEC2Describe`), just set `prometheus_iam_instance_profile` in your
`.tfvars` to that profile's name — `main.tf` attaches it as-is, no extra
resources needed.

If you only have a bare IAM **role** with no profile, you'd instead need a
`data "aws_iam_role"` lookup plus an `aws_iam_instance_profile` resource to
wrap it — ask if you need that version instead.

Only `prometheus` gets the IAM instance profile attached; `elk`, `frontend`,
`node-1`, and `node-2` do not.

## Usage
1. Copy the example vars file and fill in your real values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Edit `terraform.tfvars`:
   - `ami_id` → your AMI ID
   - `security_group_ids` → your existing security group IDs
   - `prometheus_iam_instance_profile` → your IAM instance profile name
   - `subnet_id` → optional, set or leave `null`
3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Customizing instances
Instance names come from the `instance_names` list in `variables.tf`:

```hcl
variable "instance_names" {
  type    = list(string)
  default = ["prometheus", "node-1", "node-2", "elk", "frontend"]
}
```

- **To add/remove an instance**: edit this list.
- **To change which names get `t3.medium`**: edit the `contains([...])` check
  in `main.tf`'s `instance_type` line (currently `prometheus`, `elk`).
- **To change which names get the `Monitoring = true` tag**: edit the
  `contains([...])` check in `main.tf`'s `tags` block (currently `node-1`, `node-2`).
- **To change which names get the IAM instance profile**: edit the
  `each.key == "prometheus"` check on `iam_instance_profile`.

Note: since sizing/tagging is name-based conditional logic rather than a
per-instance map, any new name not covered by the `contains()` checks will
default to `t3.micro` with no extra tags and no IAM profile.

## Files
- `main.tf` — provider + `aws_instance` resource (uses `for_each = toset(var.instance_names)`)
- `variables.tf` — all input variables, including the `instance_names` list
- `outputs.tf` — instance IDs, private IPs, public IPs
- `terraform.tfvars.example` — template for your real values