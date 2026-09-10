#!/bin/bash
# Golden AMI bootstrap script for Project 02
# Target: Amazon Linux 2023
#
# Usage:
#   - MANUAL AMI BUILD (recommended first pass): launch a plain AL2023 t2.micro,
#     SCP or paste this script, run it via SSH, verify the app works, THEN
#     create the AMI from that running instance (aws ec2 create-image).
#   - LAUNCH TEMPLATE USERDATA (once ASG is built): this same script can be
#     passed as userdata IF you decide to skip the Golden AMI step entirely
#     and bootstrap on every instance launch instead. Not the plan for this
#     project (we're doing pre-baked AMI + userdata is empty/minimal), but
#     documented here since it's a legitimate alternative pattern.

set -euo pipefail

echo "=== Updating system packages ==="
dnf update -y

echo "=== Installing Apache (httpd) ==="
dnf install -y httpd

echo "=== Enabling and starting httpd ==="
systemctl enable httpd
systemctl start httpd

echo "=== Confirming SSM agent status (should be preinstalled on AL2023) ==="
systemctl status amazon-ssm-agent --no-pager || echo "WARNING: SSM agent not found - investigate before proceeding"

echo "=== Installing CloudWatch agent ==="
dnf install -y amazon-cloudwatch-agent

echo "=== Applying CloudWatch agent config ==="
# cloudwatch-agent-config.json must be present alongside this script
# (copied to the instance before running, e.g. via scp or embedded in userdata).
cp cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "=== Confirming CloudWatch agent is running ==="
systemctl status amazon-cloudwatch-agent --no-pager || echo "WARNING: CloudWatch agent not running - investigate"

echo "=== Pulling app source from repo ==="
cd /tmp
git clone --depth 1 https://github.com/NotHarshhaa/DevOps-Projects.git repo-temp
cp -r repo-temp/DevOps-Project-02/html-web-app/* /var/www/html/
rm -rf repo-temp

echo "=== Setting ownership/permissions ==="
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

echo "=== Restarting httpd to ensure content is served ==="
systemctl restart httpd

echo "=== Bootstrap complete ==="
