


.\scripts\destroy-infrastructure.ps1 -SkipConfirmation# =============================================================================
# Configuration Switch Script for Elasticsearch Terraform
# =============================================================================
# This script allows you to switch between development and production configurations
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod")]
    [string]$Mode
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

function Switch-ToDevelopment {
    Write-Header "Switching to Development Configuration"
    
    # Backup current main.tf
    if (Test-Path "main.tf") {
        Copy-Item "main.tf" "main.tf.backup" -Force
        Write-ColorOutput "✓ Backed up main.tf to main.tf.backup" $Green
    }
    
    # Remove existing main.tf and rename development configuration
    if (Test-Path "main-dev.tf") {
        if (Test-Path "main.tf") {
            Remove-Item "main.tf" -Force
        }
        Rename-Item "main-dev.tf" "main.tf" -Force
        Write-ColorOutput "✓ Switched to development configuration" $Green
    } else {
        Write-ColorOutput "✗ Development configuration (main-dev.tf) not found" $Red
        exit 1
    }
    
    # Comment out S3 backend
    if (Test-Path "backend.tf") {
        $backendContent = Get-Content "backend.tf" -Raw
        $backendContent = $backendContent -replace '^terraform \{', '# terraform {'
        $backendContent = $backendContent -replace '^\s*backend "s3" \{', '#   backend "s3" {'
        $backendContent = $backendContent -replace '^\s*bucket =', '#     bucket ='
        $backendContent = $backendContent -replace '^\s*key\s*=', '#     key    ='
        $backendContent = $backendContent -replace '^\s*region =', '#     region ='
        $backendContent = $backendContent -replace '^\s*encrypt =', '#     encrypt ='
        $backendContent = $backendContent -replace '^\s*\}', '#   }'
        $backendContent = $backendContent -replace '^\}', '# }'
        Set-Content "backend.tf" $backendContent
        Write-ColorOutput "✓ Commented out S3 backend configuration" $Green
    }
    
    # Enable local backend
    if (Test-Path "backend-local.tf") {
        $localBackendContent = Get-Content "backend-local.tf" -Raw
        $localBackendContent = $localBackendContent -replace '^# terraform \{', 'terraform {'
        $localBackendContent = $localBackendContent -replace '^#   backend "local" \{', '  backend "local" {'
        $localBackendContent = $localBackendContent -replace '^#     path =', '    path ='
        $localBackendContent = $localBackendContent -replace '^#   \}', '  }'
        $localBackendContent = $localBackendContent -replace '^# \}', '}'
        Set-Content "backend-local.tf" $localBackendContent
        Write-ColorOutput "✓ Enabled local backend configuration" $Green
    }
    
    Write-ColorOutput "`n🎯 Development configuration activated!" $Green
    Write-ColorOutput "You can now run Terraform commands without AWS credentials." $Yellow
}

function Switch-ToProduction {
    Write-Header "Switching to Production Configuration"
    
    # Restore original main.tf
    if (Test-Path "main.tf.backup") {
        if (Test-Path "main.tf") {
            Remove-Item "main.tf" -Force
        }
        Rename-Item "main.tf.backup" "main.tf" -Force
        Write-ColorOutput "✓ Restored production configuration" $Green
    } else {
        Write-ColorOutput "✗ Production configuration backup not found" $Red
        exit 1
    }
    
    # Uncomment S3 backend
    if (Test-Path "backend.tf") {
        $backendContent = Get-Content "backend.tf" -Raw
        $backendContent = $backendContent -replace '^# terraform \{', 'terraform {'
        $backendContent = $backendContent -replace '^#   backend "s3" \{', '  backend "s3" {'
        $backendContent = $backendContent -replace '^#     bucket =', '    bucket ='
        $backendContent = $backendContent -replace '^#     key\s*=', '    key    ='
        $backendContent = $backendContent -replace '^#     region =', '    region ='
        $backendContent = $backendContent -replace '^#     encrypt =', '    encrypt ='
        $backendContent = $backendContent -replace '^#   \}', '  }'
        $backendContent = $backendContent -replace '^# \}', '}'
        Set-Content "backend.tf" $backendContent
        Write-ColorOutput "✓ Uncommented S3 backend configuration" $Green
    }
    
    # Disable local backend
    if (Test-Path "backend-local.tf") {
        $localBackendContent = Get-Content "backend-local.tf" -Raw
        $localBackendContent = $localBackendContent -replace '^terraform \{', '# terraform {'
        $localBackendContent = $localBackendContent -replace '^  backend "local" \{', '#   backend "local" {'
        $localBackendContent = $localBackendContent -replace '^    path =', '#     path ='
        $localBackendContent = $localBackendContent -replace '^  \}', '#   }'
        $localBackendContent = $localBackendContent -replace '^\}', '# }'
        Set-Content "backend-local.tf" $localBackendContent
        Write-ColorOutput "✓ Disabled local backend configuration" $Green
    }
    
    Write-ColorOutput "`n🎯 Production configuration activated!" $Green
    Write-ColorOutput "AWS credentials required for Terraform operations." $Yellow
}

function Show-Status {
    Write-Step "Current Configuration Status"
    
    Write-ColorOutput "`nMain Configuration:" $Cyan
    if (Test-Path "main.tf") {
        $mainContent = Get-Content "main.tf" -Raw
        if ($mainContent -match "skip_credentials_validation = true") {
            Write-ColorOutput "✓ Development configuration active" $Green
        } else {
            Write-ColorOutput "✓ Production configuration active" $Green
        }
    } else {
        Write-ColorOutput "✗ Main configuration not found" $Red
    }
    
    Write-ColorOutput "`nBackend Configuration:" $Cyan
    if (Test-Path "backend.tf") {
        $backendContent = Get-Content "backend.tf" -Raw
        if ($backendContent -match "^# terraform \{") {
            Write-ColorOutput "✓ S3 backend commented out (local mode)" $Green
        } else {
            Write-ColorOutput "✓ S3 backend active (production mode)" $Green
        }
    } else {
        Write-ColorOutput "✗ Backend configuration not found" $Red
    }
    
    Write-ColorOutput "`nLocal Backend:" $Cyan
    if (Test-Path "backend-local.tf") {
        $localBackendContent = Get-Content "backend-local.tf" -Raw
        if ($localBackendContent -match "^terraform \{") {
            Write-ColorOutput "✓ Local backend active" $Green
        } else {
            Write-ColorOutput "✓ Local backend commented out" $Green
        }
    } else {
        Write-ColorOutput "✗ Local backend configuration not found" $Red
    }
}

function Write-Step {
    param([string]$Step)
    Write-Host "`n▶ $Step" -ForegroundColor $Yellow
}

# Main execution
try {
    Write-Header "Elasticsearch Terraform - Configuration Switch"
    
    # Check if we're in the right directory
    if (-not (Test-Path "main.tf")) {
        Write-ColorOutput "✗ Error: main.tf not found. Please run this script from the project root directory." $Red
        exit 1
    }
    
    # Show current status
    Show-Status
    
    # Execute the requested switch
    switch ($Mode.ToLower()) {
        "dev" {
            Switch-ToDevelopment
        }
        "prod" {
            Switch-ToProduction
        }
    }
    
    # Show final status
    Show-Status
    
    Write-ColorOutput "`n🎉 Configuration switch completed successfully!" $Green
    
    # Provide next steps
    if ($Mode.ToLower() -eq "dev") {
        Write-ColorOutput "`nNext steps for development:" $Cyan
        Write-ColorOutput "1. Run: terraform init" $Yellow
        Write-ColorOutput "2. Run: terraform plan -var-file=environments/development/terraform.tfvars" $Yellow
        Write-ColorOutput "3. Run: terraform apply (when ready)" $Yellow
    } else {
        Write-ColorOutput "`nNext steps for production:" $Cyan
        Write-ColorOutput "1. Ensure AWS credentials are configured" $Yellow
        Write-ColorOutput "2. Run: terraform init -migrate-state" $Yellow
        Write-ColorOutput "3. Run: terraform plan" $Yellow
        Write-ColorOutput "4. Run: terraform apply" $Yellow
    }
    
} catch {
    Write-ColorOutput "`n✗ Configuration switch failed with error: $($_.Exception.Message)" $Red
    Write-ColorOutput "Please check the error details above and try again." $Red
    exit 1
}
