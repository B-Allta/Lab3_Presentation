<# =============================================================
 IT305 - Virtual Machines and Hosts (Lab 3 Presentation)
 Author: Bryan Treanton
 Instructor: Sims
============================================================= #>

function Banner {
    param([string]$Title)
    Clear-Host
    $w = 80
    try { if ([Console]::WindowWidth -gt 0) { $w = [Console]::WindowWidth } } catch {}
    $line = ("=" * ([Math]::Max(3, ($w - 1))))
    Write-Host $line -ForegroundColor Green
    Write-Host ("  " + $Title) -ForegroundColor Green
    Write-Host $line -ForegroundColor Green
}

function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("== " + $Title) -ForegroundColor Green
    Write-Host ("-" * ([Math]::Max(3, $Title.Length + 3))) -ForegroundColor DarkGreen
}

function Spacer { Write-Host "" }
function Label { param([string]$Text) Write-Host ("  " + $Text) -ForegroundColor Yellow }
function Note  { param([string]$Text) Write-Host ("    " + $Text) -ForegroundColor Gray }
function Code  { param([string]$Text) Write-Host ("    " + $Text) -ForegroundColor Cyan }
function Pause-Show {
    Write-Host ""
    [void](Read-Host "Press ENTER to return to menu")
}

$vb  = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"

function Slide-1 {
    Banner "PART 1: Export Windows 11 VM from Hyper-V"
    Section "Stop VM"
    Label "Command"
    Code  'Stop-VM -Name "TEAMHOME-Win11-HV" -Force'
    Label "What it does"
    Note  "Stops the VM so the export is consistent."
    Spacer
    Section "Export VM to folder"
    Label "Command"
    Code  'Export-VM -Name "TEAMHOME-Win11-HV" -Path "C:\IT305\Exports\Win11_HV"'
    Label "What it does"
    Note  "Writes configuration, snapshots, and virtual disks to the export path."
    Spacer
    Section "Verify exported files"
    Label "Command"
    Code  'Get-ChildItem "C:\IT305\Exports\Win11_HV" -Recurse | Select Name,Length'
    Label "What it does"
    Note  "Shows what the export produced."
    Spacer
    Section "Observation"
    Note  "C: was low on space. Provisioned E: for large image files."
    Pause-Show
}

function Slide-2 {
    Banner "PART 2: Prepare E: for large things n stuff"
    Section "Select large unlettered partition on Disk 1"
    Label "Command"
    Code  '$part = Get-Partition -DiskNumber 1 | Where-Object { -not $_.DriveLetter -and $_.Size -gt 1GB }'
    Label "What it does"
    Note  "Finds a suitable partition to mount as E:"
    Spacer
    Section "Assign drive letter"
    Label "Command"
    Code  'Set-Partition -DiskNumber 1 -PartitionNumber $part.PartitionNumber -NewDriveLetter E'
    Label "What it does"
    Note  "Mounts the partition as E:"
    Spacer
    Section "Format NTFS and label Data"
    Label "Command"
    Code  'Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false'
    Label "What it does"
    Note  "Formats for large VDI/VHDX files."
    Spacer
    Section "Verify volume"
    Label "Command"
    Code  'Get-Volume -DriveLetter E | Format-List DriveLetter,FileSystem,Size,SizeRemaining,DriveType'
    Label "What it does"
    Note  "Confirms drive and free space."
    Spacer
    Section "Ensure destination folders on E:"
    Label "Command"
    Code  'New-Item -ItemType Directory -Force -Path "E:\IT305\VMs\VirtualBox" | Out-Null'
    Label "What it does"
    Note  "Creates the folder tree for the converted VDI."
    Pause-Show
}

function Slide-3 {
    Banner "PART 3: Convert disk and build VirtualBox VM"
    Section "Use VBoxManage from PowerShell"
    Label "Commands"
    Code  '$vb = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"'
    Code  '& $vb --version'
    Label "What it does"
    Note  "Stores the VBoxManage path in $vb and calls it with the PowerShell call operator (&)."
    Spacer
    Section "Clone Hyper-V VHDX to VirtualBox VDI on E:"
    Label "Commands"
    Code  '$src  = "C:\IT305\VMs\HyperV\TEAMHOME-Win11-HV.vhdx"'
    Code  '$dest = "E:\IT305\VMs\VirtualBox\TEAMHOME-Win11-VB.vdi"'
    Code  'New-Item -ItemType Directory -Force -Path "E:\IT305\VMs\VirtualBox" | Out-Null'
    Code  '& $vb clonemedium disk "$src" "$dest" --format VDI'
    Label "What it does"
    Note  "Creates a VirtualBox VDI from the Hyper-V VHDX, targeting E: to avoid C: space issues."
    Spacer
    Section "Create and register the VirtualBox VM"
    Label "Commands"
    Code  '$VM  = "TEAMHOME-Win11-VB"'
    Code  '& $vb createvm --name $VM --register'
    Label "What it does"
    Note  "Registers an empty VM definition."
    Spacer
    Section "Hardware profile and start"
    Label "Commands"
    Code  '& $vb modifyvm $VM --ostype Windows11_64 --memory 4096 --cpus 2 --boot1 disk --graphicscontroller vmsvga'
    Code  '& $vb storagectl $VM --name "SATA" --add sata --controller IntelAhci'
    Code  '& $vb storageattach $VM --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$dest"'
    Code  '& $vb modifyvm $VM --nic1 nat'
    Code  '& $vb startvm $VM --type gui'
    Label "What it does"
    Note  "Sets OS type, RAM, CPU, boot order, graphics, attaches the VDI, enables NAT, and starts the VM."
    Pause-Show
}

function Slide-4 {
    Banner "PART 4: RAM scaling on Windows (VirtualBox)"
    Section "Down to 2 GB"
    Label "Commands"
    Code  '& $vb controlvm "TEAMHOME-Win11-VB" poweroff'
    Code  '& $vb modifyvm "TEAMHOME-Win11-VB" --memory 2048'
    Code  '& $vb startvm  "TEAMHOME-Win11-VB" --type gui'
    Label "What it does"
    Note  "Hard stop, set 2048 MB, boot. In guest: Get-ComputerInfo | Select CsName, CsTotalPhysicalMemory"
    Spacer
    Section "Up to 8 GB"
    Label "Commands"
    Code  '& $vb controlvm "TEAMHOME-Win11-VB" poweroff'
    Code  '& $vb modifyvm "TEAMHOME-Win11-VB" --memory 8192'
    Code  '& $vb startvm  "TEAMHOME-Win11-VB" --type gui'
    Label "What it does"
    Note  "Set 8192 MB and boot. Then checked memory inside Windows."
    Spacer
    Section "Back to 4 GB"
    Label "Commands"
    Code  '& $vb controlvm "TEAMHOME-Win11-VB" poweroff'
    Code  '& $vb modifyvm "TEAMHOME-Win11-VB" --memory 4096'
    Label "What it does"
    Note  "Reset to 4096 MB to finish."
    Pause-Show
}

function Slide-5 {
    Banner "PART 5: Ubuntu migration to Hyper-V and VM build"
    Section "Clone VDI to VHD with VBoxManage"
    Label "Commands"
    Code  '$vb   = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"'
    Code  '$src  = "C:\Users\Administrator\VirtualBox VMs\TEAMHOME-Ubuntu-VB\TEAMHOME-Ubuntu-VB.vdi"'
    Code  '$vhdd = "C:\IT305\VMs\HyperV\TEAMHOME-Ubuntu-HV.vhd"'
    Code  'New-Item -ItemType Directory -Force -Path (Split-Path $vhdd) | Out-Null'
    Code  '& $vb clonemedium disk "$src" "$vhdd" --format VHD'
    Label "What it does"
    Note  "Outputs a Hyper-V readable VHD from the VirtualBox VDI."
    Spacer
    Section "Convert VHD to VHDX with Hyper-V tools"
    Label "Command"
    Code  'Convert-VHD -Path "C:\IT305\VMs\HyperV\TEAMHOME-Ubuntu-HV.vhd" -DestinationPath "C:\IT305\VMs\HyperV\TEAMHOME-Ubuntu-HV.vhdx" -VHDType Dynamic'
    Label "What it does"
    Note  "Creates a dynamic VHDX."
    Spacer
    Section "Create Hyper-V VM and attach the VHDX"
    Label "Commands"
    Code  '$VM = "TEAMHOME-Ubuntu-HV"'
    Code  'New-VM -Name $VM -Generation 1 -MemoryStartupBytes 2GB -VHDPath "C:\IT305\VMs\HyperV\TEAMHOME-Ubuntu-HV.vhdx" -SwitchName "Default Switch"'
    Code  'Set-VMProcessor -VMName $VM -Count 2'
    Code  'Set-VMMemory -VMName $VM -DynamicMemoryEnabled $true -MinimumBytes 1GB -StartupBytes 2GB -MaximumBytes 4GB'
    Code  'Start-VM $VM'
    Code  'Get-VM $VM | Select Name, State, MemoryAssigned, CPUUsage'
    Label "What it does"
    Note  "Builds the VM, sets CPU and memory policy, starts it, and shows quick status."
    Pause-Show
}

function Slide-6 {
    Banner "PART 6: RAM tests on Ubuntu (Hyper-V)"
    Section "Set to 1 GB"
    Label "Commands"
    Code  'Stop-VM -VMName "TEAMHOME-Ubuntu-HV" -Force'
    Code  'Set-VMMemory -VMName "TEAMHOME-Ubuntu-HV" -DynamicMemoryEnabled $false -StartupBytes 1GB'
    Code  'Start-VM "TEAMHOME-Ubuntu-HV"'
    Label "What it does"
    Note  "Fixed startup memory 1 GB. In guest: free -h"
    Spacer
    Section "Set to 2 GB"
    Label "Commands"
    Code  'Stop-VM -VMName "TEAMHOME-Ubuntu-HV" -Force'
    Code  'Set-VMMemory -VMName "TEAMHOME-Ubuntu-HV" -DynamicMemoryEnabled $false -StartupBytes 2GB'
    Code  'Start-VM "TEAMHOME-Ubuntu-HV"'
    Spacer
    Section "Set to 4 GB, then back to 2 GB"
    Label "Commands"
    Code  'Stop-VM -VMName "TEAMHOME-Ubuntu-HV" -Force'
    Code  'Set-VMMemory -VMName "TEAMHOME-Ubuntu-HV" -DynamicMemoryEnabled $false -StartupBytes 4GB'
    Code  'Start-VM "TEAMHOME-Ubuntu-HV"'
    Code  '# back to 2 GB'
    Code  'Stop-VM -VMName "TEAMHOME-Ubuntu-HV" -Force'
    Code  'Set-VMMemory -VMName "TEAMHOME-Ubuntu-HV" -DynamicMemoryEnabled $false -StartupBytes 2GB'
    Code  'Start-VM "TEAMHOME-Ubuntu-HV"'
    Pause-Show
}

function Slide-7 {
    Banner "PART 7: Guest Additions (Windows VM) "
    Section "Mount ISO"
    Label "Steps"
    Note  "Devices > Insert Guest Additions CD Image"
    Spacer
    Section "Run installer"
    Label "Steps"
    Note  "Run VBoxWindowsAdditions.exe as Administrator; accept defaults; reboot"
    Spacer
    Section "Post-check"
    Label "Steps"
    Note  "Enable shared clipboard and drag-and-drop (bidirectional) in Devices menu"
    Pause-Show
}

function Show-Menu {
    Banner "IT305 Lab 3 - Presentation Menu"
    Write-Host "  1) Export Windows 11 from Hyper-V"                    -ForegroundColor Green
    Write-Host "  2) Prepare E: (assign, format, verify)"               -ForegroundColor Green
    Write-Host "  3) Convert VHDX -> VDI on E: and build VB VM"         -ForegroundColor Green
    Write-Host "  4) RAM scaling - Windows on VirtualBox"               -ForegroundColor Green
    Write-Host "  5) Ubuntu: VDI -> VHD -> VHDX and build in Hyper-V"   -ForegroundColor Green
    Write-Host "  6) RAM tests - Ubuntu on Hyper-V"                     -ForegroundColor Green
    Write-Host "  7) Guest Additions "            -ForegroundColor Green
    Write-Host "  8) Exit"                                              -ForegroundColor Green
    Spacer
}

$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host "Select 1-8"
    switch ($choice) {
        '1' { Slide-1 }
        '2' { Slide-2 }
        '3' { Slide-3 }
        '4' { Slide-4 }
        '5' { Slide-5 }
        '6' { Slide-6 }
        '7' { Slide-7 }
        '8' { $running = $false }
        default { }
    }
}
Write-Host "Done." -ForegroundColor Green
