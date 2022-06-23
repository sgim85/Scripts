
clear

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO

# Masks CC number. The first 4 and last 4 digits remain as-is. Everything in-between should be an 'X' 
function MaskCreditCardNum
{
    param([string]$creditCardNum)

    # Maximum length of value is 19. Actual CC number could be less than 19 digits. Get index of last digit in CC num.
    $indexOfLastDigit = $creditCardNum.Length - 1;

    for ($i = $creditCardNum.Length - 1; $i -ge 0; $i--)
    {
        if ([string]::IsNullOrWhiteSpace($creditCardNum[$i]) -eq $False)
        {
            $indexOfLastDigit = $i;
            break;
        }
    }

    # Do masking here
    $maskedCreditCardNum = "";
    for ($j = 0; $j -lt $creditCardNum.Length; $j++)
    {
        if (($j -lt 6) -or ($j -gt $indexOfLastDigit - 4) -or [string]::IsNullOrWhiteSpace($creditCardNum[$j]))
        {
            $maskedCreditCardNum += $creditCardNum[$j];
        }
        else
        {
            $maskedCreditCardNum += "X";
        }
    }

    return $maskedCreditCardNum;
}


# Location of the original zip files
$dirPath = 'C:\temp\f1'

# Location of the new processed zip files
$unzipDirPath = 'C:\temp\f2'

# Location of where files are unzipped
$tempDir = 'C:\temp\f3'

# Regex to replace matches
$regex = '(?<=^BKP[0-9 ]{22}.{21})([\w ]{19})'

$counter = 1

dir -Path $dirPath | foreach {
    Write-Host "`n -----------------------ZipFile $($counter)--------------------------- `n"

    # Delete existing files from the temporary folder (scratch board folder)
    Get-ChildItem -Path $tempDir -Include * | remove-Item -recurse 

    Write-Host "Extracting $($_.FullName) to folder $($tempDir)"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($_.FullName, $tempDir)

    $zipFolderName = $unzipDirPath + '\' + $_.BaseName

    dir -Path $tempDir | foreach {

        Write-Host "Processing file $($_.FullName). Replace regex match."
        (Get-Content $_.FullName) | Foreach-Object { [regex]::Replace($_, $regex, {param($match) "$(MaskCreditCardNum $match.Groups[0].Value)"}) } | Set-Content $_.FullName

        Write-Host "Creating new folder $($zipFolderName)"
        [System.IO.Directory]::CreateDirectory($zipFolderName) | Out-Null

        Write-Host "Move processed file $($_.FullName) to new folder $($zipFolderName)" 
        [System.IO.File]::Move($_.FullName, $zipFolderName + '\' + $_.Name)

        $newZipFolderName = $zipFolderName + '.zip'

        if ([System.IO.File]::Exists($newZipFolderName))
        {
            [System.IO.File]::Delete($newZipFolderName);
        }

        Write-Host "Compress folder $($zipFolderName) to create new zip $($newZipFolderName)" 
        [System.IO.Compression.ZipFile]::CreateFromDirectory($zipFolderName, $newZipFolderName) | Out-Null

        Write-Host "Delete new folder $($zipFolderName)"
        [System.IO.Directory]::Delete($zipFolderName, $True)
    }
    $counter += 1
}

Write-Host "`n`n======================= Completed! Processed $($counter - 1) zip files ======================`n`n"

# Test the CC Masking function. Maximum CC num count is 19 according to IATA specs
<#
$ccNum = '5587009998324181   ';
Write-Host -NoNewline "`nCC num to mask = ";
Write-Host -NoNewline "$ccNum" -BackgroundColor DarkRed;
Write-Host "";
Write-Host "Length of unmasked CC num = $($ccNum.Length)";
$newCCNum = MaskCreditCardNum $ccNum;
Write-Host "Masked CC num = $newCCNum";
Write-Host "Length of masked CC num = $($newCCNum.Length)";
#>


# Testing regex replace by calling the masking function
<#
$dirPath = 'C:\temp\f3'
$regex = "(?<=^BKP[0-9 ]{22}CC[0-9\w ]{19})([0-9 ]{19})";
dir -Path $dirPath | foreach { (Get-Content $_.FullName) | Foreach-Object { 
    [regex]::Replace($_, $regex, {param($match) "$(MaskCreditCardNum $match.Groups[0].Value)"})
} | Set-Content $_.FullName }
#>

<#
EX = (?<=^BKP[0-9 ]{22}EX[\w{ ]{19})([\w ]{19})


#>
