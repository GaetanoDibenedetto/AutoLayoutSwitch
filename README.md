# AutoLayoutSwitch

A set of PowerShell scripts that automatically change your Windows keyboard layout the moment a specific USB or Bluetooth keyboard is connected or disconnected. 

This repository includes two versions of the automation to suit your preference:
1. **Event-Driven Version (`AutoSwitchKeyboard.ps1`)**: Registers a Windows Management Instrumentation (WMI) event listener. It stays in a deep sleep (consuming 0% CPU) until Windows physically notifies it that the target hardware was connected. Highly recommended.
2. **Polling Version (`AutoSwitchKeyboard_Polling.ps1`)**: A simpler script that checks for connected devices every 3 seconds. It uses slightly more CPU (around 1%) but doesn't rely on Windows WMI events, making it a bulletproof fallback if the event-driven version encounters permission or threading issues on your system.

## 🚀 Features
* **Two Architecture Choices**: Choose between ultra-efficient 0% CPU WMI events or a simple polling fallback.
* **Instant Switching**: Uses native Windows API (`PostMessage`) to force the layout change globally and instantly across all windows.
* **Debounced Logging**: Ignores duplicate hardware events triggered by multi-interface USB devices.
* **Silent Execution**: Includes a VBScript launcher to run the automation completely hidden from the taskbar.

## ⚙️ Configuration

Before running the script, open `AutoSwitchKeyboard.ps1` in a text editor and adjust the `CONFIGURATION` section to match your setup:

1. **`$TargetKeyboardHWID`**: The Hardware ID of the keyboard you want to trigger the switch. By default, it's set to `"VID_0C45&PID_800A"` (a common ID for generic/custom mechanical keyboards like the F108 Pro).
   * *Tip: To find your keyboard's ID, run this in PowerShell while it is plugged in:*
     ```powershell
     Get-PnpDevice -Class Keyboard | Select-Object FriendlyName, InstanceId
     ```
2. **`$F108LayoutTip` & `$F108LayoutHex`**: The Input Method and Layout Hex ID to switch to when the keyboard is **connected**.
3. **`$DefaultLayoutTip` & `$DefaultLayoutHex`**: The Input Method and Layout Hex ID to switch back to when the keyboard is **disconnected**.

## 💻 How to Use

### Test Mode (Visible Terminal)
To test if it detects your keyboard correctly:
1. Right-click `AutoSwitchKeyboard.ps1`.
2. Select **"Run with PowerShell"**.
3. Plug and unplug your keyboard to watch the logs in real-time.

### Silent Mode (Background)
Once configured, you don't want a terminal window open all the time:
1. Depending on which script you want to use, double-click either:
   * **`RunHidden.vbs`** (for the Event-Driven version)
   * **`RunHidden_Polling.vbs`** (for the Polling version)
2. The script will now run silently in the background.

### Run on Startup
To make this automation permanent:
1. Press `Win + R`, type `shell:startup`, and hit Enter.
2. Create a shortcut to your chosen `.vbs` launcher inside that folder.

## 🔗 References & Custom Layouts

If you are looking for an excellent custom keyboard layout to use with this script (for example, typing Italian characters comfortably on a physical US layout keyboard), check out this repository:

* **[US Keyboard with Italian Letters](https://github.com/Sclafus/us_keyboard_with_italian_letters)** by [@Sclafus](https://github.com/Sclafus)
