#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%

if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; 全局状态
addMode := false


F7::
    addMode := !addMode
    if (addMode)
    {
        Menu, Tray, Tip, 加喵~模式：已开启
        TrayTip, 加喵~模式, 已开启，当前QQ聊天会自动加喵~, 2, 1
    }
    else
    {
        Menu, Tray, Tip, 加喵~模式：已关闭
        TrayTip, 加喵~模式, 已关闭, 2, 0
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

    ; 非阻塞启动，最多等5秒，避免卡住脚本
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

    ; 没开启加喵~模式，原样发送
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
    txt := txt . "喵~"

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
