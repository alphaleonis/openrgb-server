[CmdletBinding(DefaultParameterSetName = 'Build')]
param (
   [Parameter(Mandatory = $true, ParameterSetName = 'Build')]
   [ValidateNotNullOrEmpty()]
   [ArgumentCompleter({
         param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
         . $PSScriptRoot\build-vars.ps1
         
         try {            
            $versions = @(Get-GitLabTags | ForEach-Object { $_.Release })
            return ($versions + 'preview') -like "$wordToComplete*" 
         }
         catch {
            Write-Host "Error fetching tags for completion. $_"
            return @()
         }
      })]
   [string] $Version,
   [switch] $NoBuild,
   [switch] $Push,
   [string] $PAT
)

if ($Push -and !$PAT) {
   if ($env:GHCR_PAT) {
      $PAT = $env:GHCR_PAT
   }
   else {
      Write-Error "The -Push switch requires a Personal Access Token (PAT) to be provided via the -PAT parameter or in the GHCR_PAT  environment variable."
      exit 1
   }
}


. $PSScriptRoot\build-vars.ps1

$ErrorActionPreference = 'Stop'

$dockerTags = @()
if ($Version -ne 'preview') {

   # Fetch tags from GitLab API
   $tags = @(Get-GitLabTags)
   
   # Search for the matching tag
   $matchingTag = $tags | Where-Object { $_.Version -eq "$Version" }
   
   if (!$matchingTag) {
      Write-Error "Release $Version not found in repository."
      exit 1
   }

   # Determine if the matched tag is the latest release
   $latestTag = $tags | Select-Object -First 1
   if ($matchingTag.Name -eq $latestTag.Name) {
      Write-Host "The specified version $Version is the latest release." -ForegroundColor Green
      $dockerTags += 'latest'
   }
   else {
      Write-Host "Latest release is $($latestTag.Version)" -ForegroundColor Yellow
   }

   $dockerTags += $Version
   $tagName = $matchingTag.tag
   Write-Host "Building image from tag $tagName" -ForegroundColor Green
}
else {
   # Fetch information about the last commit on master, including the commit hash and date/time.
   $commitInfo = Get-LastGitLabCommit
   Write-Host "Building image from latest commit on master" -ForegroundColor Green
   $dockerTags += 'latest-preview'
   $dockerTags += "preview-$($commitInfo.created_at.ToString('yyyyMMdd-HHmmss'))"
   $tagName = $null
}

# create an array consisting of elements "-t" and the tag names. Each tag name should be preceded by a "-t"
$dargs = @()
foreach ($tag in $dockerTags) {
   $dargs += "-t"
   $dargs += "ghcr.io/alphaleonis/openrgb-server:$tag"
}

if ($tagName) {
   $dargs += "--build-arg"
   $dargs += "OPENRGB_VERSION=$tagName"
}

$dargs += @(
   "$PSScriptRoot"   
)

if (!$NoBuild) {
   Write-Host -ForegroundColor Cyan "docker build $dargs"
   docker build @dargs

   if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to build Docker image."
      exit 1
   }   
}


if ($Push) {
   $PAT | docker login ghcr.io -u alphaleonis --password-stdin
   if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to login to the registry."
      exit 1
   }

   $dockerTags | ForEach-Object {
      $tag = $_
      docker push "ghcr.io/alphaleonis/openrgb-server:$tag"
      if ($LASTEXITCODE -ne 0) {
         Write-Error "Failed to push image to registry."
         exit 1
      }
   }
}


