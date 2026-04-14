# Lab 04 — Full Cloud Deployment

## Objective

Deploy the multi-resource example from [`05-examples/example-04-multi-resource/`](../05-examples/example-04-multi-resource/).

---

## Steps

1. Navigate to the example:
```bash
cd 05-examples/example-04-multi-resource
```

2. Run:
```bash
terraform init
terraform plan
terraform apply
```

3. After apply, copy the `web_server_public_ip` from the output.

4. Open a browser and visit: `http://<public_ip>`
   - You should see the nginx welcome page.

5. Explore the state:
```bash
terraform state list
terraform state show aws_instance.web
```

6. Clean up:
```bash
terraform destroy
```

---

## Deliverable

Screenshot of:
- `terraform apply` completion
- nginx welcome page in browser
- `terraform state list` output
