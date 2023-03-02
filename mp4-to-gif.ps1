<#

	.SYNOPSIS
		Converts an mp4-file to an optimized gif-file

	.DESCRIPTION
		Converts an mp4-file to an optimized gif-file using ffmpeg.exe and gifsicle.exe. These programs are
		prerequisites so make sure they exist in your PATH environment variable.

	.PARAMETER InputFile
		Name of the mp4-file to be used as input
	
	.PARAMETER OutputFile
		Name of the gif file to be generated

	.PARAMETER Fps
		Optional parameter to set the FPS used when converting from mp4 to gif. Default value `15`
	
	.PARAMETER Width
		Optional parameter to set the width used when converting from mp4 to gif. Aspect-ratio is maintained. Default value `320`.
#>

param(
	# Input file name
	[Parameter(Mandatory=$true)]
	[string]$InputFile,
	
	# Output file name
	[Parameter(Mandatory=$true)]
	[string]$OutputFile,

	# FPS of the generated gif-file
	[Parameter()]
	[string]$Fps = 15,

	# Width of the generated gif-file, aspect-ratio is maintained
	[Parameter()]
	[string]$Width = 320
)

$ErrorActionPreference = 'Stop';
$InputFilePath = "$($PSScriptRoot)\$($InputFile)"
$OutputFilePath = "$($PSScriptRoot)\$($OutputFile)"

if ((Test-Path -Path $InputFilePath -PathType Leaf) -ne $true) {
	Write-Error "No such path $($InputFilePath)";
	exit 1;
}

$PaletteFilePath = "$($PSScriptRoot)\palette.png"

$ArgumentList = "-y","-i",$InputFilePath,"-filter_complex",'"[0:v] palettegen"',$PaletteFilePath

$PaletteGen = Start-Process -FilePath "ffmpeg.exe" -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden

while ($PaletteGen.HasExited -ne $true) {
	Write-Progress "Generating palette file...";
}

if ($PaletteGen.ExitCode -ne 0) {
	Write-Error "Error invoking ffmpeg.exe for palettegen"
	exit 1
}

$IntermediateGifFilePath = "$($PSScriptRoot)\unoptimized.gif";
$ArgumentList = "-y","-i",$InputFilePath,"-i",$PaletteFilePath,"-filter_complex","""[0:v] fps=$($Fps),scale=$($Width):-1 [new];[new][1:v] paletteuse""",$IntermediateGifFilePath

$GifGen = Start-Process -FilePath "ffmpeg.exe" -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden

while ($GifGen.HasExited -ne $true) {
	Write-Progress "Generating unoptimized gif file...";
}

if ($GifGen.ExitCode -ne 0) {
	Write-Error "Error invoking ffmpeg.exe for conversion to gif file"
	exit 1
}

$ArgumentList = "-O3","--lossy=100",$IntermediateGifFilePath,"-o",$OutputFilePath

$GifOptimize = Start-Process -FilePath "gifsicle.exe" -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden

while ($GifOptimize.HasExited -ne $true) {
	Write-Progress "Optimizing final output gif file..."
}

if ($GifOptimize.ExitCode -ne 0) {
	Write-Error "Error invoking gifsicle.exe for optimization of gif file"
	exit 1
}

Write-Host "Cleaning up ..."
Remove-Item $IntermediateGifFilePath
Remove-Item $PaletteFilePath
Write-Host "Finished generating optimized gif file $($OutputFilePath)"