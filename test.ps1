param(
    [string]$CI = $env:CI
)

function Run-Test {
    param(
        [string]$CI
    )

    if ($CI) {
        Write-Output "Running tests in a CI/CD environment"

        # Test the script in a CI/CD environment
        & .\go.ps1 -Command update
        & .\go.ps1 -Command update
        & .\go.ps1 -Command remove
        & .\go.ps1 -Command remove
        & .\go.ps1 -Command install
        & .\go.ps1 -Command install
        & .\go.ps1 -Command help
        & .\go.ps1 -Command install -Version 1.19.2

    } else {
        Write-Output "Running tests locally (DOCKER ENVIRONMENT TEST TO PREVENT SIDE EFFECTS)"
        Write-Output "This may take a while..."

        # Check if Docker is installed
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            Write-Output "Docker is not installed"
            exit 1
        }

        # Test the script in a Docker environment (with docker security and isolation to prevent side effects)
        $dockerTestResult = docker run --rm -e TERM=xterm -v "${PWD}:/app" -w /app mcr.microsoft.com/powershell:latest pwsh -Command {
            apt-get update
            apt-get install -y curl
            .\go.ps1 -Command update
            .\go.ps1 -Command update
            .\go.ps1 -Command remove
            .\go.ps1 -Command remove
            .\go.ps1 -Command install
            .\go.ps1 -Command install
            .\go.ps1 -Command help
            .\go.ps1 -Command install -Version 1.19.2
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Output "Docker test failed"
            exit $LASTEXITCODE
        } else {
            Write-Output "Docker test passed"
        }

        Remove-Item -Recurse -Force .\go
    }
}

Run-Test -CI $CI