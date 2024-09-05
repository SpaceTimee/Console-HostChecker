param ([switch] $trans)

if ($trans) { Start-Transcript (Join-Path $PSScriptRoot "Trans.log") -UseMinimalHeader | Out-Null }

if ($PSEdition -ne "Core") {
    Write-Host "Console HostChecker 需要在 PowerShell 7.x 环境运行"
}
else {
    foreach ($ps1File in Get-ChildItem $PSScriptRoot "*.ps1") {
        if ($ps1File.FullName -ne $PSCommandPath) { . $ps1File.FullName }
    }

    [App]::new().Main()
}

if ($trans) { Stop-Transcript }
else { Read-Host "按回车键结束" }