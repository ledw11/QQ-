#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%

if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}


addMode := false


F7::
    addMode := !addMode
    if (addMode)
    {
        Menu, Tray, Tip,已开启
        TrayTip, 已开启, 2, 1
    }
    else
    {
        Menu, Tray, Tip, 已关闭
        TrayTip, 已关闭, 2, 0
    }
return


F8::
    hWnd := WinExist("A")
    WinGetTitle, dTitle, A
    WinGet, dProc, ProcessName, A

    psLine := "Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes; $w=[System.Windows.Automation.AutomationElement]::FromHandle(" . hWnd . "); if($w -eq $null){Write-Output 'NULL';exit}; $c=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty,[System.Windows.Automation.ControlType]::Text); $ts=$w.FindAll([System.Windows.Automation.TreeScope]::Descendants,$c); $r=''; foreach($t in $ts){$n=$t.Current.Name;if($n -ne ''){$r+=$n+'||'}}; Write-Output $r"

    psFile := A_Temp "\qq_diag.ps1"
    outFile := A_Temp "\qq_out.txt"
    FileDelete, %psFile%
    FileDelete, %outFile%
    FileAppend, %psLine%, %psFile%


    Run, cmd /c "powershell -ExecutionPolicy Bypass -File ""%psFile%"" > ""%outFile%""",, Hide
    Loop, 50
    {
        Sleep, 100
        IfExist, %outFile%
        {
            ; 确认文件写入完成（大小不为0且稳定）
            FileGetSize, sz1, %outFile%
            Sleep, 200
            FileGetSize, sz2, %outFile%
            if (sz1 > 0 && sz1 = sz2)
                break
        }
    }

    IfExist, %outFile%
    {
        FileRead, uiText, %outFile%
    }
    else
    {
        uiText := "(读取超时，QQ窗口可能不支持UI自动化读取)"
    }

    FileDelete, %psFile%
    FileDelete, %outFile%

    StringReplace, uiText, uiText, ||, `n, All
    MsgBox, 窗口标题: [%dTitle%]`n进程: [%dProc%]`n句柄: [%hWnd%]`n`n=== 窗口内可读文本 ===`n%uiText%
return

#If WinActive("ahk_exe QQ.exe")

Enter::
^Enter::
    useCtrl := (A_ThisHotkey = "^Enter")


    if (!addMode)
    {
        if (useCtrl)
        {
            Send ^Enter
        }
        else
        {
            Send {Enter}
        }
        return
    }

    oldClip := ClipboardAll
    Clipboard := ""

    Send ^a
    Sleep 80
    Send ^c
    ClipWait, 1

    txt := Clipboard

    if (ErrorLevel || txt = "")
    {
        Clipboard := oldClip
        if (useCtrl)
        {
            Send ^Enter
        }
        else
        {
            Send {Enter}
        }
        return
    }

    txt := RegExReplace(txt, "[\s。！？!?~…,，.、；;：:]+$", "")
    txt := txt . "改成你要加的特定词"

    Clipboard := ""
    Clipboard := txt
    Sleep 100
    Send ^v
    Sleep 150

    if (useCtrl)
    {
        Send ^Enter
    }
    else
    {
        Send {Enter}
    }

    Sleep 300
    Clipboard := oldClip
return

#If

F9::ExitApp

