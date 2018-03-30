<# 
 USMT_Calgon.ps1
 Created by Kristopher Roy
 Created - 21MArch18
 Updated - 30March18
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
	   Function Run-USMT ($type,$path,$storepath,$migapps,$migdocs,$overwrite,$config,$continue,$logging)
	   {
           $dir = $path
           if ([System.IntPtr]::Size -eq 4) {$bit = "x86" } else {$bit = "amd64" }
		   if(!(Test-Path $dir\USMT)){$usmtpath = ((Get-Folder -Description "Select USMT Root Folder")+"\"+$bit)}
           ELSE{write-host "$dir\USMT";$usmtpath = "$dir\USMT\$bit"}
		   if($type -eq "restore")
		   {
            IF($migapps -eq $True){$migapps = "/i:$usmtpath\migapp.xml"}
            IF($migdocs -eq $True){$migdocs = "/i:$usmtpath\migdocs.xml"}
            IF($config -eq $True){$config = "/i:$usmtpath\Config_AppsAndSettings.xml"}
            IF($continue -eq $True){$continue = "/c"}
            IF($logging -eq $True){$log = "/L:"+$storepath+"scanstate.log"}
            IF($logging -eq $True){$loggingtype = "/v:1"}
            $restoreargs = @($storepath,$migapps,$migdocs,$overwrite,$continue,$log,$loggingtype)
            $loadstatepath = $usmtpath+"\loadstate.exe"	    
            &$loadstatepath $restoreargs
		   }
		   if($type -eq "capture")
		   {
            IF($migapps -eq $True){$migapps = "/i:$usmtpath\migapp.xml"}
            IF($migdocs -eq $True){$migdocs = "/i:$usmtpath\migdocs.xml"}
            IF($config -eq $True){$config = "/i:$usmtpath\Config_AppsAndSettings.xml"}
            IF($overwrite -eq $True){$overwrite = "/o"}
            IF($continue -eq $True){$continue = "/c"}
            IF($logging -eq $True){$log = "/L:"+$storepath+"\capturestate.log"}
            IF($logging -eq $True){$loggingtype = "/v:1"}
            $captureargs = @($storepath,$migapps,$migdocs,$overwrite,$continue,$log,$loggingtype)
            $scanstatepath = $usmtpath+"\scanstate.exe"
            &$scanstatepath $captureargs
		   }
	   }

#set script path
$scriptpath = split-path -parent $MyInvocation.MyCommand.Definition

#Set script to pre-migration, or post for collecting or pushing data
$migrationtype = MultipleSelectionBox -inputarray "Pre-Migration","Post-Migration" -listboxtype One -label "Pre or Post User State Migration" -prompt "Migration Point" -sizeX 350 -sizeY 320

#Pre-Migration Tasks
If($migrationtype -eq "Pre-Migration")
{
	$computername = $env:computername
	$pclocal = MultipleSelectionBox  -inputarray "Big Sandy","Columbus","Gilla Bend","GSK(hq)/UVG/EAP","NIP","PRP(Pearl River)","NTP(North Tonowada)","YellowTavern","LocalDrive","ManualInput" -listboxtype One -label "Where to Store Migration Data" -prompt "Migration Data" -sizeX 350 -sizeY 320
    IF($pclocal -eq "LocalDrive"){$StorePath = Get-Folder -Description "Where do you wish to store the capture files?"}
    IF($pclocal -eq "Big Sandy"){$StorePath = "\\abkpbsp01\migrations\$computername\"}
	IF($pclocal -eq "Columbus"){$StorePath = "\\abkpcol2\migrations\$computername\"}
	IF($pclocal -eq "Gilla Bend"){$StorePath = "\\gbppw001\migrations\$computername\"}
	IF($pclocal -eq "GSK(hq)/UVG/EAP"){$StorePath = "\\afspit\migrations\$computername\"}
	IF($pclocal -eq "NIP"){$StorePath = "\\afsnip2\migrations\$computername\"}
	IF($pclocal -eq "NTP"){$StorePath = "\\afsntp1\migrations\$computername\"}
	IF($pclocal -eq "YellowTavern"){$StorePath = "\\BTL-YT-DFS02\migrations\$computername\"}
	IF($pclocal -eq "ManualInput")
	{
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$StorePath = [Microsoft.VisualBasic.Interaction]::InputBox("Type the path for migration storage location", "FolderPath", "\\server\migdata\$computername\")
	}
    Run-USMT -type capture -path $scriptpath -storepath $StorePath -migapps:$true -config:$true -overwrite:$true -continue:$true -logging:$true -migdocs:$true

    #Run-USMT -path $scriptpath -type capture
}

#Post-Migration Tasks
If($migrationtype -eq "Post-Migration")
{
	$pclocal = MultipleSelectionBox  -inputarray "Big Sandy","Columbus","Gilla Bend","GSK(hq)/UVG/EAP","NIP","PRP(Pearl River)","NTP(North Tonowada)","YellowTavern","LocalDrive","ManualInput" -listboxtype One -label "Where Migration Data is Stored" -prompt "Migration Data" -sizeX 350 -sizeY 320
	#[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
	#$oldpc = [Microsoft.VisualBasic.Interaction]::InputBox("Please enter the name of the Old PC", "PCName", "wpitzousto") 

	IF($pclocal -eq "ManualInput")
	{
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$StorePath = [Microsoft.VisualBasic.Interaction]::InputBox("Type the path for migration storage location", "FolderPath", "\\server\migdata\$oldpc\USMT\")
	}
	IF($pclocal -eq "LocalDrive"){$ServerPath = Get-Folder -Description "Select the server and migrations root"}
    IF($pclocal -eq "Big Sandy"){$ServerPath = "\\abkpbsp01\migrations"}
	IF($pclocal -eq "Columbus"){$ServerPath = "\\abkpcol2\migrations"}
	IF($pclocal -eq "Gilla Bend"){$ServerPath = "\\gbppw001\migrations"}
	IF($pclocal -eq "GSK(hq)/UVG/EAP"){$ServerPath = "\\afspit\migrations"}
	IF($pclocal -eq "NIP"){$ServerPath = "\\afsnip2\migrations"}
	IF($pclocal -eq "NTP"){$ServerPath = "\\afsntp1\migrations"}
	IF($pclocal -eq "YellowTavern"){$ServerPath = "\\BTL-YT-DFS02\migrations"}

    $oldpclist = GCI $ServerPath -Name
    $PCName = MultipleSelectionBox  -inputarray $oldpclist  -listboxtype One -label "Select The Old PC" -prompt "PC Name" -sizeX 350 -sizeY 320  
    $StorePath =  "$ServerPath\$PCName\"
	Run-USMT -type restore -path $scriptpath -storepath $StorePath -migapps:$true -config:$true -continue:$true -logging:$true -migdocs:$true
}

Read-Host "Press ENTER to Continue"