﻿<#
 USMT-Script.ps1
 Created by Kristopher Roy
 Created - 20MAarch18
 Modified - 23MArch18
 Requirements: This script requires that the USMT has been downloaded and is available
#>

#Functions Section

       #This function lets you build an array of specific list items you wish
       Function MultipleSelectionBox ($inputarray,$prompt,$listboxtype,$label,$sizeX,$sizeY) {

       # Taken from Technet - http://technet.microsoft.com/en-us/library/ff730950.aspx
       # This version has been updated to work with Powershell v3.0.
       # Had to replace $x with $Script:x throughout the function to make it work. 
       # This specifies the scope of the X variable.  Not sure why this is needed for v3.
       # http://social.technet.microsoft.com/Forums/en-SG/winserverpowershell/thread/bc95fb6c-c583-47c3-94c1-f0d3abe1fafc
       #
       # Function has 3 inputs:
       #     $inputarray = Array of values to be shown in the list box.
       #     $prompt = The title of the list box
       #     $listboxtype = system.windows.forms.selectionmode (None, One, MultiSimple, or MultiExtended)

       $Script:x = @()

       [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
       [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
 
       $objForm = New-Object System.Windows.Forms.Form 
       $objForm.Text = $prompt
	   If($sizeX -eq $null -or $sizeX -eq ""){$sizeX = 300}
	   If($sizeY -eq $null -or $sizeY -eq ""){$sizeY = 600}
	   $objForm.Size = New-Object System.Drawing.Size($sizeX,$sizeY)
       #if($objForm.Size -eq $null -or $objForm.Size -eq ""){$objForm.Size = New-Object System.Drawing.Size(300,600) }
       $objForm.StartPosition = "CenterScreen"

       $objForm.KeyPreview = $True

       $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
              {
                     foreach ($objItem in $objListbox.SelectedItems)
                           {$Script:x += $objItem}
                     $objForm.Close()
              }
              })

       $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
              {$objForm.Close()}})

       $OKButton = New-Object System.Windows.Forms.Button
       #$OKButton.Location = New-Object System.Drawing.Size(75,520)
       $OKButtonX = (($sizeX/2)-90)
       $OKButtonY = ($sizeY-80)
	   $OKButton.Location = New-Object System.Drawing.Size($OKButtonX,$OKButtonY)
       $OKButton.Size = New-Object System.Drawing.Size(75,23)
       $OKButton.Text = "OK"

       $OKButton.Add_Click(
          {
                     foreach ($objItem in $objListbox.SelectedItems)
                           {$Script:x += $objItem}
                     $objForm.Close()
          })

       $objForm.Controls.Add($OKButton)

       $CancelButton = New-Object System.Windows.Forms.Button
       $CancelButton.Location = New-Object System.Drawing.Size(150,520)
       $CancelButton.Location = New-Object System.Drawing.Size(($OKButtonX+80),($OKButtonY))
       $CancelButton.Size = New-Object System.Drawing.Size(75,23)
       $CancelButton.Text = "Cancel"
       $CancelButton.Add_Click({$objForm.Close()})
       $objForm.Controls.Add($CancelButton)

       $objLabel = New-Object System.Windows.Forms.Label
       $objLabel.Location = New-Object System.Drawing.Size(10,20) 
       $objLabel.Size = New-Object System.Drawing.Size(280,20) 
       $objLabel.Text = $label
       if($objLabel.Text -eq $null -or $objLabel.Text -eq ""){$objLabel.Text = "Please make a selection from the list below:"}
       $objForm.Controls.Add($objLabel) 
 
       $objListbox = New-Object System.Windows.Forms.Listbox 
       $objListbox.Location = New-Object System.Drawing.Size(10,40) 
       $objListbox.Size = New-Object System.Drawing.Size(260,40) 
 
       $objListbox.SelectionMode = $listboxtype

       $inputarray | ForEach-Object {[void] $objListbox.Items.Add($_)}

       $objListbox.Height = ($sizey)-40
       $objListbox.Width = $sizex-42
       $objForm.Controls.Add($objListbox) 
       $objForm.Topmost = $True

       $objForm.Add_Shown({$objForm.Activate()})
       [void] $objForm.ShowDialog()

       Return $Script:x
       }

	   #This Function creates a dialogue to return a Folder Path
       function Get-Folder {
              param([string]$Description="Select Folder to place results in",[string]$RootFolder="Desktop")

       [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
              Out-Null     

          $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
                     $objForm.Rootfolder = $RootFolder
                     $objForm.Description = $Description
                     $Show = $objForm.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
                     If ($Show -eq "OK")
                     {
                           Return $objForm.SelectedPath
                     }
                     Else
                     {
                           Write-Error "Operation cancelled by user."
                     }
       }

	   #This Function sets up the USMT to be used with POSH commands
	   Function Run-USMT ($type,$path,$storepath)
	   {
           $dir = $path
           if ([System.IntPtr]::Size -eq 4) {$bit = "x86" } else {$bit = "amd64" }
		   if(!(Test-Path $dir\USMT)){$usmtpath = ((Get-Folder -Description "Select USMT Root Folder")+"\"+$bit)}
           ELSE{write-host "$dir\USMT";$usmtpath = "$dir\USMT\$bit"}
		   if($type -eq "capture")
		   {
            $captureargs = @($storepath)
            $scanstatepath = $usmtpath+"\scanstate.exe"
            &$scanstatepath $captureargs
		   }
		   if($type -eq "restore")
		   {
            $restoreargs = @($storepath)
            $loadstatepath = $usmtpath+"\loadstate.exe"			    
            &$loadstatepath $restoreargs
		   }
	   }
#set script path
$scriptpath = split-path -parent $MyInvocation.MyCommand.Definition

#Set script to pre-migration, or post for collecting or pushing data
$migrationtype = MultipleSelectionBox -inputarray "Pre-Migration","Post-Migration" -listboxtype One -label "Pre or Post User State Migration" -prompt "Migration Point" -sizeX 350 -sizeY 220

#Pre-Migration Tasks
If($migrationtype -eq "Pre-Migration")
{
	$computername = $env:computername
	$pclocal = MultipleSelectionBox  -inputarray "ManualInput","LocalDrive" -listboxtype One -label "Where to Store Migration Data" -prompt "Migration Data" -sizeX 350 -sizeY 220
	IF($pclocal -eq "ManualInput")
	{
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$StorePath = [Microsoft.VisualBasic.Interaction]::InputBox("Type the path for migration storage location", "FolderPath",  "\\server\migdata\$computername\")
	}
	IF($pclocal -eq "LocalDrive"){$StorePath = Get-Folder -Description "Where do you wish to store the capture files?"}
	Run-USMT -type capture -path $scriptpath -storepath $StorePath
}

#Post-Migration Tasks
If($migrationtype -eq "Post-Migration")
{
	$pclocal = MultipleSelectionBox  -inputarray "ManualInput","LocalDrive" -listboxtype One -label "Where is Migration Data Stored" -prompt "Migration Data" -sizeX 350 -sizeY 220
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
	$oldpc = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter the name of the Old PC", "PCName", "OldPCName")
	IF($pclocal -eq "ManualInput")
	{
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$StorePath = [Microsoft.VisualBasic.Interaction]::InputBox("Type the path for migration storage location", "FolderPath", "\\server\migdata\OldComputerName\USMT\")
	}
	IF($pclocal -eq "LocalDrive"){$StorePath = Get-Folder -Description "Where are the capture files stored?"}
	Run-USMT -type restore -path $scriptpath -storepath $StorePath
}