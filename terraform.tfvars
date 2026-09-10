# Actual values used for this project run.
# Defaults in variables.tf already match our planned CIDR table,
# so this file mostly exists to override profile/region if needed
# and to serve as the single "source of truth" reference during apply.

aws_region  = "ap-southeast-1"
aws_profile = "default" # change if using a named profile
