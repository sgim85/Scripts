
<#
Reads .wpl (Windows Player List) and moves music files from one location to another
#>

clear;

$fileCount = 0;

$files = @(Get-ChildItem "C:\Music\d")
foreach ($file in $files) {

    Write-Host $file
    Write-Host $file.FullName
    #Write-Host $file.FullName

    [XML]$details = Get-Content $file.FullName -Encoding UTF8

    foreach($detail in $details.smil.body.seq.media)
    {
        $path = [System.IO.Path]::Combine($file.Directory.FullName, $detail.src);

        $path = [System.IO.Path]::GetFullPath($path);

        $exists = [System.IO.File]::Exists($path)
        if ($exists -eq $false)
        {
            Write-Host "Playlist file not found!" -ForegroundColor Red
            Write-Host "   |__"$path
            continue;
        }
        #Write-Host "   |__"$path

        $parts = $path -split "\\"

        $artist = ""
        if ($detail.albumArtist){
            $artist = $detail.albumArtist
        } 
        if (!$artist -and $detail.trackArtist){
            $artist = $detail.trackArtist
        }
        
        $track = ""
        if ($parts[$parts.Length - 1]){
            $track = $parts[$parts.Length - 1]
        } 
        if (!$track -and $detail.trackTitle){
            $track = $detail.trackTitle + ".mp3"
        }

        $album = ""
        if ($detail.albumTitle){
            $album = $detail.albumTitle
        }
        if (!$album -and $parts.Length -ge 2 -and $parts[$parts.Length - 2]){
            $album = $parts[$parts.Length - 2]
        } 
        $album = $album.Replace(":", " -")

        if (!$track -or !$album){
            Write-Host "Track details incomplete!"
            Write-Host "   |__Artist:"$artist", Album:"$album", Track:"$track -ForegroundColor Red
            continue
        }

        $dir = "C:\Music2\$artist\$album"
        if (!$artist){
            $dir = "C:\Music2\$album"
        }

        $newPath = $dir + "\" + $track
        
        Write-Host "Created track: "$newPath

        if (![System.IO.Directory]::Exists($dir))
        {
            Write-Host "Create Directory: "$dir
            [System.IO.Directory]::CreateDirectory($dir);
        }

        #COPIES FILE TO NEW LOCATION
        #Copy-Item -Path $path -Destination $newPath -Force -Recurse
        #Copy-Item -Path $path -Destination $dir -Force
        if (![System.IO.File]::Exists($newPath)){
            [System.IO.File]::Copy($path, $newPath, $true)
        }
    }

    $newPL = "C:\Music2\Playlists\$file"

    # COPIES PLAYLIST TO NEW LOCATION
    Copy-Item $file.FullName -Destination C:\Music2\Playlists\ -force 

    [XML]$xml = Get-Content $newPL -Encoding UTF8

    $nodes = $xml.SelectNodes("smil/body/seq/media");
    foreach($node in $nodes) {
        $path = $node.src
        $parts = $path -split "\\"

        <#
        $artist = ""
        if (![string]::IsNullOrEmpty($node.albumArtist)){
            $artist = $node.albumArtist + "\"
        } 
        if ([string]::IsNullOrEmpty($artist) -and ![string]::IsNullOrEmpty($node.trackArtist)){
            $artist = $node.trackArtist + "\"
        }
        #>
        $artist = ""
        if ($node.albumArtist){
            $artist = $node.albumArtist
        } 
        if (!$artist -and $node.trackArtist){
            $artist = $node.trackArtist
        }
        
        
        $track = ""
        if ($parts[$parts.Length - 1]){
            $track = $parts[$parts.Length - 1]
        } 
        if (!$track -and $node.trackTitle){
            $track = $node.trackTitle + ".mp3"
        }

        $album = ""
        if ($node.albumTitle){
            $album = $node.albumTitle
        }
        if (!$album -and $parts.Length -ge 2 -and $parts[$parts.Length - 2]){
            $album = $parts[$parts.Length - 2]
        } 
        $album = $album.Replace(":", " -")

        $newPath = "..\$artist" + "\" + $album + "\" + $track
        if (!$artist){
            $newPath = "..\$album" + "\" + $track
        }

        if (!$track -or !$album){
            Write-Host "2. Track details incomplete!"
            Write-Host "   |__Artist:"$artist", Album:"$album", Track:"$track -ForegroundColor Red
            continue
        }

        $_p = [System.IO.Path]::GetFullPath("C:\Music2\Playlists\" + $newPath);
        if(![System.IO.File]::Exists($_p)){
            Write-Host "Create Directory: "$dir
            Write-Host "Track not found: "$_p 
        }
        else{
            $fileCount = $fileCount + 1;
        }

        $node.SetAttribute("src", "$newPath");
    }
    $xml.Save($newPL)
    
}

Write-Host "Created Files "$fileCount

