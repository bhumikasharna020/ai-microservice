# Copy screenshots to clean names
Copy-Item "docs\Screenshot 2026-07-11 021832.png" "docs\cluster-active.png" -Force
Copy-Item "docs\Screenshot 2026-07-11 032816.png" "docs\loki.png.png" -Force
Copy-Item "docs\Screenshot 2026-07-11 033155.png" "docs\k8s dashboard.png.png" -Force
Copy-Item "docs\Screenshot 2026-07-11 033122.png" "docs\k8s dashboard2.png.png" -Force

# Re-run PDF/Word compiler script
PowerShell.exe -ExecutionPolicy Bypass -File "C:\Users\hp\.gemini\antigravity\brain\5925c198-4daf-45a9-8a31-50cedae9ab28\generate_report.ps1"

# Re-compress ZIP
Remove-Item "C:\Users\hp\Downloads\Assignment-corrected.zip" -ErrorAction SilentlyContinue
Compress-Archive -Path "C:\Users\hp\Downloads\Assignment-corrected" -DestinationPath "C:\Users\hp\Downloads\Assignment-corrected.zip" -Force

# Git operations
& "C:\Program Files\Git\cmd\git.exe" add --all
& "C:\Program Files\Git\cmd\git.exe" commit -m "docs: finalize EKS cluster setup logs and regenerate submission report"
& "C:\Program Files\Git\cmd\git.exe" push origin main
