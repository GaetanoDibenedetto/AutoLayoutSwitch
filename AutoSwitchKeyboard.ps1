# ----------------------------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------------------------
# 1. Hardware ID of the F108 Pro Keyboard
# Default is 'VID_0C45&PID_800A' which is common for generic mechanical keyboards.
# If this doesn't work, plug in the keyboard and check Device Manager or run: 
# Get-PnpDevice -Class Keyboard | Select-Object FriendlyName, InstanceId
$TargetKeyboardHWID = "VID_0C45&PID_800A"

# 2. Layout to use when the F108 Pro is CONNECTED
# E.g., "0409:00000409" for US, "0409:A0000409" for US-International
# "0409:00000410" for English Language with Italian Keyboard Layout
$F108LayoutTip = "0409:A0000409"  
$F108LayoutHex = "A0000409"

# 3. Layout to use when the F108 Pro is DISCONNECTED (your default)
# Default Italian is "0410:00000410"
$DefaultLayoutTip = "0410:00000410"
$DefaultLayoutHex = "00000410"

# ----------------------------------------------------------------------------------
# SCRIPT LOGIC (Do not edit below unless you know what you're doing)
# ----------------------------------------------------------------------------------

$code = @"
using System;
using System.Runtime.InteropServices;
public class KLSwitch {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool PostMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    [DllImport("user32.dll")]
    public static extern IntPtr LoadKeyboardLayout(string pwszKLID, uint Flags);
    
    public const int HWND_BROADCAST = 0xffff;
    public const int WM_INPUTLANGCHANGEREQUEST = 0x0050;
    public const uint KLF_ACTIVATE = 1;
    
    public static void SetLayout(string langId) {
        IntPtr layout = LoadKeyboardLayout(langId, KLF_ACTIVATE);
        PostMessage((IntPtr)HWND_BROADCAST, WM_INPUTLANGCHANGEREQUEST, 0, layout.ToInt32());
    }
}
"@
Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue

Write-Host "Monitoring for Keyboard Connection: $TargetKeyboardHWID"

# Unregister previous events if script is re-run
Get-EventSubscriber | Where-Object { $_.SourceIdentifier -match "^KeyboardEvent_" } | Unregister-Event -ErrorAction SilentlyContinue

$QueryConnect = "SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_PnPEntity' AND TargetInstance.DeviceID LIKE '%$TargetKeyboardHWID%'"
$QueryDisconnect = "SELECT * FROM __InstanceDeletionEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_PnPEntity' AND TargetInstance.DeviceID LIKE '%$TargetKeyboardHWID%'"

Register-WmiEvent -Query $QueryConnect -SourceIdentifier "KeyboardEvent_Connected" > $null
Register-WmiEvent -Query $QueryDisconnect -SourceIdentifier "KeyboardEvent_Disconnected" > $null

Write-Host "Event listeners registered. Script is sleeping efficiently."

# Keep script alive and process events on the main thread to avoid memory corruption
$isCurrentlyF108 = $null

while($true) {
    $event = Wait-Event -Timeout 3600
    if ($event) {
        if ($event.SourceIdentifier -eq "KeyboardEvent_Connected") {
            if ($isCurrentlyF108 -ne $true) {
                Write-Host "[$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))] F108 Pro connected. Switching layout to $F108LayoutTip"
                Set-WinDefaultInputMethodOverride -InputTip $F108LayoutTip -ErrorAction SilentlyContinue
                [KLSwitch]::SetLayout($F108LayoutHex)
                $isCurrentlyF108 = $true
            }
        } elseif ($event.SourceIdentifier -eq "KeyboardEvent_Disconnected") {
            if ($isCurrentlyF108 -ne $false) {
                Write-Host "[$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))] F108 Pro disconnected. Switching layout to $DefaultLayoutTip"
                Set-WinDefaultInputMethodOverride -InputTip $DefaultLayoutTip -ErrorAction SilentlyContinue
                [KLSwitch]::SetLayout($DefaultLayoutHex)
                $isCurrentlyF108 = $false
            }
        }
        Remove-Event -EventIdentifier $event.EventIdentifier
    }
}
