
# Build and Deploy Nuget package

function Show-Options
{
     #cls
     Write-Host "-------- Options --------"
    
     Write-Host "Press '1' to create nuget package for a specific project"
     Write-Host "Press 'q' to quit"
}

function CreateNugetPackages
{
    param(
        [string]$csprojPath,
        [string]$version, # E.g. 1.2.0
        [bool]$isBeta = $true
    )

    $csprojPath = $csprojPath.Trim()
    $version = $version.Trim()

    if ([System.IO.File]::Exists($csprojPath) -eq $false)
    {
        Write-Host "Path $($csprojPath) does not exist." -ForegroundColor Red
        return;
    }

    if ($version -notmatch "\d{1,3}\.\d{1,4}\.\d{1,4}")
    {
        Write-Host "Invalid version# $($version). Must be in format Major.Minor.Release. E.g. 1.2.0" -ForegroundColor Red
        return;
    }

    #------------ Verify Version -----------------------
    # Verify that csproj version# same as provided version# ($version)
    [XML]$csprojContent = Get-Content $csprojPath -Encoding UTF8

    $csprojVersion = $csprojContent.Project.PropertyGroup.Version
    if ([string]::IsNullOrWhiteSpace($csprojVersion))
    {
        $csprojVersion = $csprojContent.Project.PropertyGroup.VersionPrefix
    }
    elseif ([string]::IsNullOrWhiteSpace($csprojContent.Project.PropertyGroup.VersionPrefix) -eq $false)
    {
        $csprojContent.Project.PropertyGroup.VersionPrefix = $csprojVersion.ToString();
    }

    # .csproj must have a version#. If not check that $version (provided to CLI) = 1.0.0 (Meaning initial version for package). We will update csproj in later step to add version info.
    if ([string]::IsNullOrWhiteSpace($csprojVersion) -and $version -ne '1.0.0')
    {
        Write-Host "Package version# missing in project. Edit project properties or add 'VersionPrefix' property to .csproj $($csprojPath)" -ForegroundColor Red
        return;
    }
    elseif ([string]::IsNullOrWhiteSpace($csprojVersion) -eq $false -and $csprojVersion -ne $version)
    {
        Write-Host "Specified version ($($version)) and .csproj version ($($csprojVersion)) do not match. Update version# to ($($version)) in project properties as well." -ForegroundColor Red
        return;
    }

    # Add 'VersionPrefix' property to csproj. 'VersionPrefix' works better than 'Version' property when using 'dotnet pack' command.
    if ([string]::IsNullOrWhiteSpace($csprojContent.Project.PropertyGroup.VersionPrefix))
    {
        $versionPrefixNode = $csprojContent.CreateElement("VersionPrefix", $csprojContent.DocumentElement.NamespaceURI)
        $versionPrefixNode.InnerText = $version
        $csprojContent.Project.PropertyGroup.AppendChild($versionPrefixNode)
    }
    # Remove 'Version' Property from csproj as it causes 'dotnet pack' command to ignore package suffix (e.g. *-beta) if you are using one.
    if ([string]::IsNullOrWhiteSpace($csprojContent.Project.PropertyGroup.Version) -eq $false)
    {
        try
        {
            $versionNode = $csprojContent.SelectNodes("/Project/PropertyGroup/Version").Item(0)
            $csprojContent.Project.PropertyGroup.RemoveChild($versionNode)
        }
        catch {}
    }

    if ([string]::IsNullOrWhiteSpace($csprojContent.Project.PropertyGroup.Authors))
    {
        $authorsNode = $csprojContent.CreateElement("Authors", $csprojContent.DocumentElement.NamespaceURI)
        $authorsNode.InnerText = "Porter Airlines Inc"
        $csprojContent.Project.PropertyGroup.AppendChild($authorsNode)
        $csprojContent.Project.PropertyGroup.Authors = "Porter Airlines Inc"
    }

    <#
    if ([string]::IsNullOrWhiteSpace($csprojContent.Project.PropertyGroup.Company))
    {
        $companyNode = $csprojContent.CreateElement("Company")
        $companyNode.InnerText = "Porter Airlines Inc"
        $csprojContent.Project.PropertyGroup.AppendChild($companyNode)
    }
    $csprojContent.Project.PropertyGroup.Company = "Porter Airlines Inc"
    #>

    $csprojContent.Save($csprojPath)


    #------------ End Verify Version -----------------------

    # Create temp folder where to dump .nupkg and .symbols.nupkg files. Will delete later.
    $tempPackFolder = "C:\data\PorterNugetPackager\PackageBin"
    New-Item -ItemType Directory -Force -Path $tempPackFolder

    # Empty existing .nupkg files
    #Get-ChildItem -Path $tempPackFolder -Include *.* -File -Recurse | foreach { $_.Delete()}

    #$libName = Split-Path $csprojPath -Leaf
    $libName = [System.IO.Path]::GetFileNameWithoutExtension($csprojPath)

    $nupkgFile = ""

    if ($isBeta)
    {
        dotnet pack $csprojPath -o $tempPackFolder --include-symbols --version-suffix "beta"
        $version = "$($version)-beta"
    }
    else
    {
        dotnet pack $csprojPath -o $tempPackFolder --include-symbols
    }

    $nupkgFile = "$($tempPackFolder)\$($libName).$($version).nupkg"

    nuget delete $libName $version -Source http://qa-nugetbuild.porter.local/api/v2/package -ApiKey 1oECoYHrxR9x6eBwmsmu -NonInteractive
    nuget push $nupkgFile 1oECoYHrxR9x6eBwmsmu -Source http://qa-nugetbuild.porter.local/api/v2/package

    Write-Host ""
    #Write-Host "Please verify packages your packages in list below. All MA.* and PB.* (excluding *-beta packages) must have same version#"
    #nuget list -Source http://qa-nugetbuild.porter.local/nuget/ -PreRelease

    #Remove-Item -path $tempPackFolder -WarningAction Ignore -Recurse
}

Show-Options

$option = Read-Host
Write-Host ""

<#
$confirm = Read-Host -Prompt "Continue with option $option [y/n]"
Write-Host ""

if ( $confirm -notmatch "[yY]" )
{
    Show-Options
}
#>

if ($option -eq '1')
{
    Write-Host "Enter the full csproj path"
    $csprojPath = Read-Host

    Write-Host ""
    Write-Host "Enter version number. E.g. 1.0.0"
    $version = Read-Host

    Write-Host ""
    $isBeta_Answer = Read-Host -Prompt "Is Beta version? [y/n]    ('Yes' if during development or before pull-request approval)"
    $isBeta = ($isBeta_Answer -match "[yY]")

    CreateNugetPackages $csprojPath $version $isBeta
}
elseif ($option -match "[qQ]")
{
    return;
}  
else{
    #Show-Options
}

<#
do
{

    switch ($input)
    {
        '1' {
            cls
            'You would like to create nuget packages for all projects in solution.'
        } '2' {
            cls
            'You would like to create nuget package for a specific project'
        } 'q' {
            return
        }
    }

}
until($option.ToLower() -eq 'q')
#>

<#
do
{
    Show-Options

    $option = Read-Host
    Write-Host ""

    switch ($option)
    {
        '1' {
            cls
            'You would like to create nuget packages for all projects in solution.'
        } '2' {
            cls
            'You would like to create nuget package for a specific project'
        } 'q' {
            return
        }
    }

}
until($option -match "[qQ]")
#>
