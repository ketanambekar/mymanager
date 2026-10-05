[CmdletBinding()]
param(
    [string]$OutputDirectory = $env:TEMP,
    [switch]$Tag
)

$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) { throw "Run this script inside the MyManager git repository." }
Set-Location $repoRoot

$pending = git status --porcelain -- server
if ($pending) {
    throw "server/ has uncommitted changes. Commit them first; the bundle contains only committed code.`n$($pending -join "`n")"
}

$version = (Get-Content server/package.json -Raw | ConvertFrom-Json).version
$commit = (git rev-parse HEAD).Trim()
$shortCommit = $commit.Substring(0, 12)
$tagName = "server-v$version"

$taggedCommit = git rev-parse --verify --quiet "refs/tags/$tagName^{commit}"
if ($taggedCommit -and $taggedCommit.Trim() -ne $commit) {
    throw "$tagName already points to $($taggedCommit.Trim().Substring(0, 12)). Bump the version (npm --prefix server run version:patch|minor|major), update server/CHANGELOG.md, and commit."
}

New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$bundle = Join-Path $OutputDirectory "mymanager-server-v$version-$shortCommit.tar.gz"
# core.autocrlf=false keeps the repository's LF line endings so shell scripts run on the Linux host.
git -c core.autocrlf=false archive --format=tar.gz "--add-virtual-file=RELEASE_COMMIT:$commit`n" -o $bundle "HEAD:server"
if ($LASTEXITCODE -ne 0) { throw "git archive failed." }

if ($Tag -and -not $taggedCommit) {
    git tag -a $tagName -m "MyManger API v$version" $commit
    if ($LASTEXITCODE -ne 0) { throw "Could not create tag $tagName." }
    Write-Host "Created tag $tagName (push with: git push origin $tagName)"
}

Write-Host "Version : $version"
Write-Host "Commit  : $commit"
Write-Host "Bundle  : $bundle"
