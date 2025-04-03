param(
    [string]$Command = "install",
    [string]$Version = "latest"
)

switch ($Command) {
    "install" {
        if ($Version -eq "latest") {
            Write-Output "Fetching the latest version of Go for Windows..."
            $GoDownloadPage = "https://go.dev/dl/"
            try {
                $WebContent = Invoke-WebRequest -Uri $GoDownloadPage -UseBasicParsing
                $LatestGoURL = ($WebContent.Content -match 'href="(https://go.dev/dl/go[0-9.]+\.windows-amd64\.msi)"') | Out-Null
                $LatestGoURL = $Matches[1]
            } catch {
                Write-Output "Error accessing the Go download page."
                exit 1
            }

            if ($LatestGoURL) {
                Write-Output "Latest version URL: $LatestGoURL"
                $InstallerPath = "$env:TEMP\go-installer.msi"
                Invoke-WebRequest -Uri $LatestGoURL -OutFile $InstallerPath
                Start-Process msiexec.exe -ArgumentList "/i $InstallerPath /quiet /norestart" -Wait
                Remove-Item $InstallerPath
                Write-Output "Latest version of Go installed successfully!"
            } else {
                Write-Output "Error: Could not find the latest version."
            }
        } else {
            Write-Output "Installing specified version of Go: $Version"
            $GoURL = "https://go.dev/dl/go${Version}.windows-amd64.msi"
            $InstallerPath = "$env:TEMP\go-installer.msi"
            try {
                Invoke-WebRequest -Uri $GoURL -OutFile $InstallerPath
                Start-Process msiexec.exe -ArgumentList "/i $InstallerPath /quiet /norestart" -Wait
                Remove-Item $InstallerPath
                Write-Output "Go version $Version installed successfully!"
            } catch {
                Write-Output "Error: Could not download or install version $Version."
            }
        }
    }
    "update" {
        Write-Output "Updating Go..."
        & $PSCommandPath -Command "remove"
        & $PSCommandPath -Command "install"
        Write-Output "Go updated successfully."
    }
    "remove" {
        Write-Output "Removing Go..."
        $GoUninstallKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "Go*" }
        if ($GoUninstallKey) {
            $UninstallString = $GoUninstallKey.UninstallString
            Start-Process -FilePath $UninstallString -ArgumentList "/quiet /norestart" -Wait
            Write-Output "Go removed successfully."
        } else {
            Write-Output "Go not found on the system."
        }
    }
    "help" {
        Write-Output @"
Usage: go.ps1 [-Command install|update|remove|help] [-Version X.X.X]
Commands:
  install - Installs Go. Use [-Version] to specify the version (default: latest).
  update  - Updates Go to the latest version.
  remove  - Removes Go from the system.
  help    - Shows this help message.
"@
    }
    default {
        Write-Output "Invalid command. Use 'install', 'update', 'remove' or 'help'."
    }
}