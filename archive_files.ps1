# Archive unused files script
$archivePath = "archive"

# Create archive subdirectories
New-Item -ItemType Directory -Force -Path "$archivePath/docs" | Out-Null
New-Item -ItemType Directory -Force -Path "$archivePath/scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$archivePath/duplicate" | Out-Null

Write-Host "Archiving documentation files..."
$docs = @(
    "AUTO_SETUP_COMPLETE.md",
    "AZURE_QUOTA_EXPLANATION.md",
    "CONNECT_TO_PI.md",
    "COPY_PASTE_TO_PI.txt",
    "DO_THIS_NOW.md",
    "FINAL_PI_SETUP.md",
    "FINAL_SETUP_STEPS.md",
    "HOW_TO_PASTE.md",
    "PI_QUICK_START.md",
    "PI_SETUP_STEPS.md",
    "QUOTA_EFFICIENT_SUMMARY.md",
    "QUOTA_OPTIMIZATION_GUIDE.md",
    "SETUP_SUMMARY.md",
    "SSH_INFO_NEEDED.md",
    "START_HERE.md",
    "TEST_IT.md",
    "UNDERSTANDING_THE_OUTPUT.md",
    "WHAT_I_NEED.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Move-Item -Path $doc -Destination "$archivePath/docs/" -Force
        Write-Host "  Archived: $doc"
    }
}

Write-Host "`nArchiving setup scripts..."
$scripts = @(
    "auto_setup_pi_complete.sh",
    "auto_setup_pi.ps1",
    "auto_setup_with_sshpass.sh",
    "auto_ssh_setup.exp",
    "check_api_status.sh",
    "complete_pi_setup.ps1",
    "do_pi_setup.ps1",
    "EXECUTE_THIS_ON_PI.sh",
    "find_pi_ip.ps1",
    "pi_setup.sh",
    "RUN_THIS.sh",
    "setup_pi_automated.ps1",
    "setup_pi_complete.sh",
    "setup_pi_files.ps1",
    "setup_pi_final.ps1",
    "setup_pi_via_wsl.sh",
    "setup_with_plink.ps1",
    "pi_heartbeat_test.py",
    "pi_heartbeat_continuous.py",
    "pi_heartbeat_efficient.py"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Move-Item -Path $script -Destination "$archivePath/scripts/" -Force
        Write-Host "  Archived: $script"
    }
}

Write-Host "`nDone! Files archived to $archivePath/"

