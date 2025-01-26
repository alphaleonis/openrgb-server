$ApiUrl = "https://gitlab.com/api/v4/projects/$([uri]::EscapeDataString("CalcProgrammer1/OpenRGB"))"
$ReleaseTagPrefix = "release_"

function Get-GitLabTags {
   $tags = Invoke-RestMethod -Uri "$ApiUrl/repository/tags?order_by=updated&sort=desc" -Method Get -MaximumRetryCount 2 -RetryIntervalSec 2 
   return $tags.name |  ForEach-Object { 
         [PSCustomObject]@{
            Name = $_
            Version = $_ -replace "^$ReleaseTagPrefix", ''
         }
      }
}

function Get-LastGitLabCommit {
   $commits = Invoke-RestMethod -Uri "$ApiUrl/repository/commits?ref_name=master" -Method Get -MaximumRetryCount 2 -RetryIntervalSec 2
   return $commits | Select-Object -First 1
}