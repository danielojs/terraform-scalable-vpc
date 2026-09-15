# Working in Codespaces

This repository defines its development environment as code. Codespaces builds
the environment from `.devcontainer/`; the same configuration works in VS Code
with the Dev Containers extension and a local Docker engine.

## Start here

Use the `codex/codespaces-devops-environment` branch to try this setup before
merging. In GitHub, select that branch, then **Code → Codespaces → Create codespace**.
Creating a separate Codespace is the easiest way to test without disturbing your
current one. After merging, new Codespaces on `main` use this configuration too.

To use your existing Codespace, first preserve your work and any local files you
need. `/workspaces` survives a rebuild, but manually installed programs and files
under the home directory, including AWS configuration and SSH keys, may not.
Keep credentials in an approved private location, never in Git. Then run:

```bash
git status
git fetch origin
git switch codex/codespaces-devops-environment
```

Resolve or save any uncommitted work before switching branches. Open the command
palette with **Ctrl+Shift+P**, select **Codespaces: Rebuild Container**, and wait
for the automatic tool check to pass.

## What is installed and why

| Tool | Version | Purpose |
| --- | --- | --- |
| Terraform | 1.16.2 | Provisioning CLI; supports this project's S3 native locking |
| AWS CLI | 2.36.45 | AWS authentication, inspection, and API commands |
| Session Manager plugin | 1.2.835.0 | Interactive SSM sessions from the terminal |
| Git, curl, jq, dig, ShellCheck | Base image / Ubuntu packages | Source control, HTTP, JSON, DNS, and shell checks |

Terraform and AWS CLI use versioned Dev Container Features. The Dockerfile adds
the Session Manager plugin from an explicit AWS release URL. Builds fail if the
installed CLI versions do not match the expected versions. The normal shell
runs as `vscode`, not root. No AWS credentials are baked into the image.

The three main CLI versions are pinned, but this is not a byte-for-byte frozen
image: the base image tag, Ubuntu packages, and a Feature's GitHub CLI dependency
can receive updates. A team needing immutable builds can additionally pin image
digests and dependency artifacts and manage their updates through pull requests.
The Session Manager package is fetched over HTTPS; this setup does not add an
independent signature verification step for that package.

## Authenticate to AWS

GitHub login and AWS login are separate. Your AWS CLI credentials authorize you;
the EC2 instance profile authorizes SSM Agent on the instance. Both sides need
their own appropriate permissions.

For an account already using IAM Identity Center, create a named profile:

```bash
aws configure sso --profile lab --use-device-code --no-browser
aws sso login --profile lab --use-device-code --no-browser
aws sts get-caller-identity --profile lab
```

Supply your actual SSO start URL, SSO region, account, and assigned role. Open the
device authorization URL in your laptop browser. The SSO region may differ from
the workload region. This flow requires Identity Center to be configured; it
does not create an SSO organization or grant access automatically.

If you already have a working AWS `default` profile, you can use it instead:

```bash
aws sts get-caller-identity --profile default
```

Do not create long-lived access keys just to build this container. If Identity
Center is not available, choose an appropriate temporary-credential login method
for your account before running AWS commands. Use Codespaces secrets only where
needed and scope them to the intended repositories; never put credentials in
the Dockerfile, devcontainer.json, Terraform variables, or committed files.

This project's provider explicitly uses `var.aws_profile`, and terraform.tfvars
sets it to `default`. For the `lab` profile, pass `-var='aws_profile=lab'` to plan.
The S3 backend has separate authentication; `AWS_PROFILE=lab` selects its profile:

```bash
AWS_PROFILE=lab terraform init
AWS_PROFILE=lab terraform plan -var='aws_profile=lab'
```

These are intentional manual commands against your configured AWS account and
backend. The container does not run them automatically. A plan inspects current
infrastructure but does not apply changes. Check the caller identity first.

## Connect to EC2 from this terminal

```bash
aws ssm start-session --profile lab \
  --region ap-southeast-1 --target YOUR_INSTANCE_ID
```

Use `default` instead of `lab` if that is your configured profile. Type `exit`
to return to Codespaces. This shell session does not require an SSH key or inbound
port 22. `TargetNotConnected` still requires troubleshooting the EC2 agent,
instance role, and outbound AWS endpoint connectivity. Installing a client in
Codespaces does not fix the instance-side error. `AccessDeniedException` calls
for checking the CLI identity's session permissions.

## Verify and maintain the environment

```bash
bash .devcontainer/verify-tools.sh
shellcheck .devcontainer/*.sh
bash .devcontainer/check-terraform.sh
terraform fmt -check -recursive
```

The Terraform check initializes and validates a temporary copy with the backend
disabled. It needs internet access for providers, but no AWS credentials; it
does not alter your existing `.terraform` directory or remote state. If a provider
lock file exists, the check uses it read-only. Formatting is checked separately
so pre-existing formatting differences do not prevent the environment building.

`.terraform.lock.hcl` is now trackable. Prefer adding the lock file from your
existing working Codespace so its tested AWS provider version is retained. Review
and commit it. If none exists, your next `terraform init` generates one. Until it
is committed, fresh environments can select different AWS 6.x provider releases.
Do not run `terraform init -upgrade` unless you intend to update providers.

The GitHub Actions workflow builds this same Dev Container and checks the tools,
shell scripts, and Terraform configuration for environment changes. It receives
no AWS secrets, does not publish an image, and does not apply infrastructure.
Action implementations are pinned to commit SHAs. Update CLI pins and their
expected versions together in a branch, let the build pass, then review and merge.

Other repositories need their own copy or shared template of this configuration.
Installing software in this Codespace does not install it into other Codespaces.

## References

- [GitHub Dev Containers](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers)
- [Files and container rebuilds](https://docs.github.com/en/codespaces/developing-in-a-codespace/rebuilding-the-container-in-a-codespace)
- [AWS CLI SSO configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [Session Manager CLI sessions](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html)
