foreach ($ps1File in Get-ChildItem $PSScriptRoot "*.ps1") {
    if ($ps1File.FullName -ne $PSCommandPath) { . $ps1File }
}

[App]::new().Main()

Read-Host "按回车键结束"