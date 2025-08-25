# 🚀 Create Clean Repository Script
# This script creates a clean repository with only essential files

Write-Host "🚀 Creating Clean Repository..." -ForegroundColor Green

# Create clean repository directory
$cleanRepoPath = ".\elastic-terraform-clean"
if (Test-Path $cleanRepoPath) {
    Remove-Item -Path $cleanRepoPath -Recurse -Force
}
New-Item -ItemType Directory -Path $cleanRepoPath | Out-Null

# Essential directories to copy
$essentialDirs = @(
    ".github",
    "environments", 
    "modules",
    "docs"
)

# Essential files to copy
$essentialFiles = @(
    "main.tf",
    "variables.tf", 
    "outputs.tf",
    "elasticsearch-values.yaml",
    "kibana-values.yaml",
    "README.md",
    "LICENSE",
    "CONTRIBUTING.md",
    ".gitignore",
    "DEPLOYMENT_GUIDE.md",
    "QUICK_START.md",
    "ARCHITECTURE_DRAWIO.xml",
    "ARCHITECTURE_ASCII_DIAGRAM.txt"
)

# Copy essential directories
foreach ($dir in $essentialDirs) {
    if (Test-Path $dir) {
        Write-Host "📁 Copying directory: $dir" -ForegroundColor Cyan
        Copy-Item -Path $dir -Destination $cleanRepoPath -Recurse -Force
    }
}

# Copy essential files
foreach ($file in $essentialFiles) {
    if (Test-Path $file) {
        Write-Host "📄 Copying file: $file" -ForegroundColor Cyan
        Copy-Item -Path $file -Destination $cleanRepoPath -Force
    }
}

# Copy PowerShell scripts (excluding problematic ones)
$scripts = Get-ChildItem -Path "." -Filter "*.ps1" | Where-Object { $_.Name -notlike "*setup-github-repo*" }
foreach ($script in $scripts) {
    Write-Host "🔧 Copying script: $($script.Name)" -ForegroundColor Cyan
    Copy-Item -Path $script.FullName -Destination $cleanRepoPath -Force
}

Write-Host "✅ Clean repository created at: $cleanRepoPath" -ForegroundColor Green
Write-Host "📊 Total files copied: $(Get-ChildItem -Path $cleanRepoPath -Recurse | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Yellow

# Navigate to clean repository
Set-Location $cleanRepoPath

Write-Host "`n🚀 Ready to initialize git repository!" -ForegroundColor Green
Write-Host "Run: git init" -ForegroundColor White
Write-Host "Run: git add ." -ForegroundColor White
Write-Host "Run: git commit -m 'Initial commit'" -ForegroundColor White
Write-Host "Run: git remote add origin https://github.com/InfraPlatformer/elastic-terraform.git" -ForegroundColor White
Write-Host "Run: git push origin main" -ForegroundColor White
