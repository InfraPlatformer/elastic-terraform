# =============================================================================
# Local Development Setup Script for Elasticsearch Terraform
# =============================================================================
# This script sets up the local development environment
# Run this script from the project root directory
# =============================================================================

param(
    [switch]$Clean,
    [switch]$Init,
    [switch]$Validate,
    [switch]$Plan,
    [switch]$All
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor $Cyan
    Write-Host " $Title" -ForegroundColor $Cyan
    Write-Host "=" * 80 -ForegroundColor $Cyan
}

function Write-Step {
    param([string]$Step)
    Write-Host "`n▶ $Step" -ForegroundColor $Yellow
}

function Test-TerraformInstallation {
    Write-Step "Checking Terraform installation..."
    
    try {
        $terraformVersion = terraform version
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Terraform is installed" $Green
            Write-Host $terraformVersion[0] -ForegroundColor $Cyan
        } else {
            throw "Terraform command failed"
        }
    }
    catch {
        Write-ColorOutput "✗ Terraform is not installed or not in PATH" $Red
        Write-ColorOutput "Please install Terraform from: https://www.terraform.io/downloads" $Red
        exit 1
    }
}

function Clean-TerraformState {
    Write-Step "Cleaning up existing Terraform state..."
    
    $itemsToRemove = @(
        ".terraform",
        ".terraform.lock.hcl",
        "terraform.tfstate",
        "terraform.tfstate.backup"
    )
    
    foreach ($item in $itemsToRemove) {
        if (Test-Path $item) {
            Remove-Item -Recurse -Force $item -ErrorAction SilentlyContinue
            Write-ColorOutput "✓ Removed $item" $Green
        } else {
            Write-ColorOutput "- $item not found (already clean)" $Cyan
        }
    }
}

function Initialize-Terraform {
    Write-Step "Initializing Terraform with local backend..."
    
    try {
        terraform init
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Terraform initialized successfully" $Green
        } else {
            throw "Terraform init failed"
        }
    }
    catch {
        Write-ColorOutput "✗ Terraform initialization failed" $Red
        Write-ColorOutput "Error: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Validate-Terraform {
    Write-Step "Validating Terraform configuration..."
    
    try {
        terraform validate
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Terraform configuration is valid" $Green
        } else {
            throw "Terraform validation failed"
        }
    }
    catch {
        Write-ColorOutput "✗ Terraform validation failed" $Red
        Write-ColorOutput "Error: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Plan-Terraform {
    Write-Step "Creating Terraform plan..."
    
    try {
        # Check if development environment variables exist
        $devVarsFile = "environments/development/terraform.tfvars"
        if (Test-Path $devVarsFile) {
            Write-ColorOutput "Using development environment variables" $Cyan
            terraform plan -var-file=$devVarsFile -out=tfplan-local
        } else {
            Write-ColorOutput "No development variables found, using defaults" $Yellow
            terraform plan -out=tfplan-local
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✓ Terraform plan created successfully" $Green
            Write-ColorOutput "Plan saved to: tfplan-local" $Cyan
        } else {
            throw "Terraform plan failed"
        }
    }
    catch {
        Write-ColorOutput "✗ Terraform plan failed" $Red
        Write-ColorOutput "Error: $($_.Exception.Message)" $Red
        exit 1
    }
}

function Show-Status {
    Write-Step "Current project status..."
    
    Write-ColorOutput "`nBackend Configuration:" $Cyan
    if (Test-Path "backend-local.tf") {
        Write-ColorOutput "✓ Local backend configured" $Green
    } else {
        Write-ColorOutput "✗ Local backend not found" $Red
    }
    
    if (Test-Path "backend.tf") {
        Write-ColorOutput "✓ S3 backend configuration available (commented)" $Green
    } else {
        Write-ColorOutput "✗ S3 backend configuration not found" $Red
    }
    
    Write-ColorOutput "`nTerraform State:" $Cyan
    if (Test-Path ".terraform") {
        Write-ColorOutput "✓ Terraform initialized" $Green
    } else {
        Write-ColorOutput "✗ Terraform not initialized" $Red
    }
    
    if (Test-Path "terraform.tfstate") {
        Write-ColorOutput "✓ Local state file exists" $Green
    } else {
        Write-ColorOutput "- No state file (normal for new setup)" $Cyan
    }
    
    Write-ColorOutput "`nEnvironment Files:" $Cyan
    $envDirs = @("development", "staging", "production")
    foreach ($env in $envDirs) {
        $envPath = "environments/$env"
        if (Test-Path $envPath) {
            Write-ColorOutput "✓ $env environment configured" $Green
        } else {
            Write-ColorOutput "- $env environment not configured" $Yellow
        }
    }
}

function Show-NextSteps {
    Write-Header "Next Steps"
    
    Write-ColorOutput "`n🎯 Your local development environment is ready!" $Green
    Write-ColorOutput "`nNext steps:" $Cyan
    Write-ColorOutput "1. Review the configuration: terraform show" $Yellow
    Write-ColorOutput "2. Test with plan: terraform plan" $Yellow
    Write-ColorOutput "3. Apply changes (if desired): terraform apply tfplan-local" $Yellow
    Write-ColorOutput "4. When ready for production, configure AWS credentials and S3 backend" $Yellow
    Write-ColorOutput "`n📚 Documentation:" $Cyan
    Write-ColorOutput "- Local Development Guide: docs/LOCAL_DEVELOPMENT.md" $Yellow
    Write-ColorOutput "- Backend Setup: docs/BACKEND_SETUP.md" $Yellow
    Write-ColorOutput "- Project README: README.md" $Yellow
}

# Main execution
try {
    Write-Header "Elasticsearch Terraform - Local Development Setup"
    
    # Check if we're in the right directory
    if (-not (Test-Path "main.tf")) {
        Write-ColorOutput "✗ Error: main.tf not found. Please run this script from the project root directory." $Red
        exit 1
    }
    
    # Check Terraform installation
    Test-TerraformInstallation
    
    # Show current status
    Show-Status
    
    # Execute requested actions
    if ($Clean -or $All) {
        Clean-TerraformState
    }
    
    if ($Init -or $All) {
        Initialize-Terraform
    }
    
    if ($Validate -or $All) {
        Validate-Terraform
    }
    
    if ($Plan -or $All) {
        Plan-Terraform
    }
    
    # Show final status and next steps
    Show-Status
    Show-NextSteps
    
    Write-ColorOutput "`n🎉 Setup completed successfully!" $Green
    
} catch {
    Write-ColorOutput "`n✗ Setup failed with error: $($_.Exception.Message)" $Red
    Write-ColorOutput "Please check the error details above and try again." $Red
    exit 1
}
