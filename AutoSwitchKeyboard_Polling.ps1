# ----------------------------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------------------------
# 1. Hardware ID of the F108 Pro Keyboard
$TargetKeyboardHWID = "VID_0C45&PID_800A"

# 2. Layout to use when the F108 Pro is CONNECTED
$F108LayoutTip = "0409:A0000409"  
$F108LayoutHex = "A0000409"

# 3. Layout to use when the F108 Pro is DISCONNECTED (your default)
$DefaultLayoutTip = "0410:00000410"
$DefaultLayoutHex = "00000410"

# ----------------------------------------------------------------------------------
# SCRIPT LOGIC (Polling Version)
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

Write-Host "Monitoring for Keyboard Connection: $TargetKeyboardHWID (Polling Mode)"

$wasConnected = $null

while ($true) {
    $devices = Get-PnpDevice -Class Keyboard -Status OK -ErrorAction SilentlyContinue
    $isConnected = $false
    
    if ($devices) {
        foreach ($dev in $devices) {
            if ($dev.InstanceId -and $dev.InstanceId -match $TargetKeyboardHWID) {
                $isConnected = $true
                break
            }
        }
    }
    
    if ($isConnected -ne $wasConnected) {
        if ($isConnected) {
            Write-Host "[$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))] F108 Pro connected. Switching layout to $F108LayoutTip"
            Set-WinDefaultInputMethodOverride -InputTip $F108LayoutTip -ErrorAction SilentlyContinue
            [KLSwitch]::SetLayout($F108LayoutHex)
        } else {
            if ($null -ne $wasConnected -or -not $isConnected) {
                Write-Host "[$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))] F108 Pro disconnected/not found. Switching layout to $DefaultLayoutTip"
                Set-WinDefaultInputMethodOverride -InputTip $DefaultLayoutTip -ErrorAction SilentlyContinue
                [KLSwitch]::SetLayout($DefaultLayoutHex)
            }
        }
        $wasConnected = $isConnected
    }
    
    Start-Sleep -Seconds 3
}
