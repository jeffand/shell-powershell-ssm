#!/usr/bin/env bash
#
# setup_single_ssm_doc_repo.sh
#
# Usage: ./setup_single_ssm_doc_repo.sh [folder_name]
# If [folder_name] is not provided, "my-ssm-doc-repo" will be used by default.

set -e

# Default folder name if none provided
REPO_NAME="${1:-my-ssm-doc-repo}"

# Create the top-level directory structure
mkdir -p "${REPO_NAME}"
mkdir -p "${REPO_NAME}/modules/ssm_document/templates"
mkdir -p "${REPO_NAME}/scripts"

# Create a top-level main.tf
cat > "${REPO_NAME}/main.tf" << EOF
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# The AWS provider will read the profile and region variables from variables.tf
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

module "ssm_document" {
  source = "./modules/ssm_document"
  document_name = "${REPO_NAME}-sh-PS1-Doc"
}
EOF

# Create a top-level variables.tf with defaults for aws_profile and aws_region
cat > "${REPO_NAME}/variables.tf" << 'EOF'
variable "aws_profile" {
  type        = string
  description = "Which AWS CLI profile to use (Ex: admin-usergroup, prod, dev)."
  default     = "admin-usergroup"
}

variable "aws_region" {
  type        = string
  description = "Which AWS region to use (Ex: us-east-1, us-west-2)."
  default     = "us-east-1"
}
EOF

# Create a top-level README.md
cat > "${REPO_NAME}/README.md" << EOF
# ${REPO_NAME}

This repository contains Terraform code to create an AWS SSM document with both shell and PowerShell script sections.

## Directory Structure

\`\`\`
${REPO_NAME}/
├── main.tf
├── variables.tf
├── README.md
├── modules
│   └── ssm_document
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── templates
│           └── ssm_document.yaml
└── scripts
    ├── linux_script.sh
    └── windows_script.ps1
\`\`\`

## Quick Start

1. Install Terraform (v1.0.0 or higher).
2. \`cd\` into this directory (\`cd ${REPO_NAME}\`).
3. Run:
   \`\`\`
   terraform init
   terraform validate
   terraform plan
   terraform apply
   \`\`\`

## Switching Accounts and Regions

To deploy to other accounts or regions, use the \`-var\` flag:

- **Different Profile** (Ex: \`prod\`):
  \`\`\`
  terraform apply -var="aws_profile=prod"
  \`\`\`
- **Different Region** (Ex: \`us-west-2\`):
  \`\`\`
  terraform apply -var="aws_region=us-west-2"
  \`\`\`
- **Both Profile and Region** (Ex: \`us-west-2 & prod\`):
  \`\`\`
  terraform apply -var="aws_region=us-west-2" -var="aws_profile=prod"
  \`\`\`

## Customizing Scripts

Inside \`scripts/\`, you can add your own commands to:
- **\`linux_script.sh\`** for Linux.
- **\`windows_script.ps1\`** for Windows.

These are referenced directly in the SSM document.

## Version Control

After setting up the project, don't forget to initialize a Git repository:

\`\`\`
git init
git add .
git commit -m "Initial commit for ${REPO_NAME}"
\`\`\`

EOF

# Create the ssm_document module files
cat > "${REPO_NAME}/modules/ssm_document/main.tf" << 'EOF'
resource "aws_ssm_document" "shell_and_powershell_doc" {
  name          = var.document_name
  document_type = "Command"

  content = templatefile("${path.module}/templates/ssm_document.yaml", {
    linux_script   = file("${path.module}/../scripts/linux_script.sh")
    windows_script = file("${path.module}/../scripts/windows_script.ps1")
  })
}
EOF

cat > "${REPO_NAME}/modules/ssm_document/variables.tf" << 'EOF'
variable "document_name" {
  type        = string
  description = "Name of the SSM document."
}
EOF

cat > "${REPO_NAME}/modules/ssm_document/outputs.tf" << 'EOF'
output "ssm_document_name" {
  value       = aws_ssm_document.shell_and_powershell_doc.name
  description = "The name of the created SSM document."
}
EOF

# Create the SSM document template
cat > "${REPO_NAME}/modules/ssm_document/templates/ssm_document.yaml" << EOF
{
  "schemaVersion": "2.2",
  "description": "SSM Document created by ${REPO_NAME}, containing both Linux and Windows scripts.",
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "${REPO_NAME}_RunLinuxScript",
      "inputs": {
        "runCommand": [
          "${linux_script}"
        ]
      }
    },
    {
      "action": "aws:runPowerShellScript",
      "name": "${REPO_NAME}_RunWindowsScript",
      "inputs": {
        "runCommand": [
          "${windows_script}"
        ]
      }
    }
  ]
}
EOF

# Create placeholder scripts
cat > "${REPO_NAME}/scripts/linux_script.sh" << 'EOF'
#!/usr/bin/env bash
echo "Running Linux script from ${REPO_NAME}..."
# Add your Linux commands here
EOF

cat > "${REPO_NAME}/scripts/windows_script.ps1" << 'EOF'
Write-Host "Running Windows script from ${REPO_NAME}..."
# Add your Windows commands here
EOF

echo "Terraform repo created in ./${REPO_NAME}"
echo "You can edit scripts under ./${REPO_NAME}/scripts/, then run 'terraform init && terraform apply' within ./${REPO_NAME}."
echo "Reminder: Don't forget to 'git init' to version control your new project!"