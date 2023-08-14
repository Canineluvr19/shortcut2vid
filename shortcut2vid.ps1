# Get-Shortcut function shamelessly stolen from ??? stack overflow.
# Modified to also return original image's LastWriteTime parameter
<#
.SYNOPSIS

.DESCRIPTION
Creates a slideshow using ffmpeg. Expects a folder of shortcuts to images.
Will copy all images into a .\ffmpeg_temp_src\ path, renamed to 0000#.png, by the file's last written date, 
runs the ffmpeg creation of the .mp4, then deletes the .\ffmpeg_temp_src\ directory

.EXAMPLE
shortcut2vid.ps1 -path egypt -output egypt -framerate 10 

.NOTES
Requires ffmpeg.exe in the path. 
Recommended install process by chocolatey, `choco install ffmpeg`
#>
param(
    [string]$output_name = "ffmpeg_created",
    [int]$framerate = 10,
    [string]$resolution,
    [string]$path
)
$ffmpeg_location = where.exe ffmpeg.exe
if(!$ffmpeg_location){
  Write-Output "ERROR: Requires ffmpeg.exe installed (and in the path)"
  Write-Output "       Try running 'choco install ffmpeg' to get it"
  exit(1)
}

# Defaults and constants
$temp_working_folder = "ffmpeg_temp_src"
if(!$path){
  $path = "."
}
function Get-Shortcut {
    param(
      $path = $null
    )
  
    $obj = New-Object -ComObject WScript.Shell
  
    if ($path -eq $null) {
      $pathUser = [System.Environment]::GetFolderPath('StartMenu')
      $pathCommon = $obj.SpecialFolders.Item('AllUsersStartMenu')
      $path = dir $pathUser, $pathCommon -Filter *.lnk -Recurse 
    }
    if ($path -is [string]) {
      $path = dir $path -Filter *.lnk
    }
    $path | ForEach-Object { 
      if ($_ -is [string]) {
        $_ = dir $_ -Filter *.lnk
      }
      if ($_) {
        $link = $obj.CreateShortcut($_.FullName)
  
        $info = @{}
        $info.Hotkey = $link.Hotkey
        $info.TargetPath = $link.TargetPath
        $info.LastWriteTime = (Get-ChildItem $link.TargetPath).LastWriteTime
        $info.LinkPath = $link.FullName
        $info.Arguments = $link.Arguments
        $info.Target = try {Split-Path $info.TargetPath -Leaf } catch { 'n/a'}
        $info.Link = try { Split-Path $info.LinkPath -Leaf } catch { 'n/a'}
        $info.WindowStyle = $link.WindowStyle
        $info.IconLocation = $link.IconLocation
  
        New-Object PSObject -Property $info
      }
    }
}

$shortcut_array = Get-Shortcut $path\*.lnk
$sorted_array = $shortcut_array | Sort-Object LastWriteTime

mkdir $temp_working_folder -ErrorAction Stop

$resolution_bins = @()
$count = 0
$sorted_array | ForEach-Object{
    $count += 1
    $new_img_name = (".\$temp_working_folder\{0:d5}.png" -f $count)
    Copy-Item $_.TargetPath $new_img_name
    $image = New-Object -ComObject Wia.ImageFile
    $image.loadfile($_.TargetPath)
    $width = $image.Width
    $height = $image.Height
    $this_resolution = "$($width)x$($height)"
    if( -not ($resolution_bins -contains $this_resolution)){
        $resolution_bins += $this_resolution
    }
}

if(-not $resolution){
    if($resolution_bins.Length -ge 2){
        $resolution = $resolution_bins[-2] # dirty hacky shit. 
    }
    else{
        $resolution = $resolution_bins[0]
    }
    # $resolution_bins are built by the loop above.
    # Above assumes that the last seen resolution is the highest (final upscaling), and returns the resolution before. 
}
if($debug){
    Write-Output $resolution_bins
    Write-Output "$resolution Selected"
}

#$resolution = "1024x1024"
ffmpeg -framerate $framerate -pattern_type sequence -start_number 00001 -i .\$temp_working_folder\%05d.png -s:v $resolution -c:v libx264 -crf 17 -pix_fmt yuv420p .\$output_name.mp4
Write-Output "Generated $output_name.mp4 video using $framerate fps @ $resolution."
Write-Output "If this looks off, the resolutions detected were: $resolution_bins."
Write-Output "resolution can be specified by the -resolution argument to this script."
Remove-Item ".\$temp_working_folder" -r -force
