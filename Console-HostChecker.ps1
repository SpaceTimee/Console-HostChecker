if ($PSEdition -ne "Core") {
    Write-Host "Console HostChecker 需要在 PowerShell 7.x 环境运行"
    Read-Host "按回车键结束"
    Exit 0
}

foreach ($ps1File in Get-ChildItem $PSScriptRoot "*.ps1") {
    if ($ps1File.FullName -ne $PSCommandPath) { . $ps1File.FullName }
}

[App]::new().Main()

Read-Host "按回车键结束"