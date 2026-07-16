param ([string] $trans, [switch] $loop, [string[]] $hosts, [switch] $remote)

do {
    if (Test-Path -LiteralPath $trans -PathType Container) {
        $null = Start-Transcript -LiteralPath (Join-Path $trans "Trans.log") -UseMinimalHeader
    }

    if (-not $IsCoreCLR) {
        Write-Host "该脚本需要在 PowerShell 7.x 环境运行"
    }
    else {
        foreach ($ps1File in Get-ChildItem -LiteralPath $PSScriptRoot "*.ps1") {
            if ($ps1File.FullName -ne $PSCommandPath) { . $ps1File.FullName }
        }

        [string] $hostPath = Join-Path $PSScriptRoot "Cealing-Host.json"
        [string] $externalHostPath = Join-Path (Get-Location) "Cealing-Host.json"

        if ($hosts.Count -eq 1 -and (Test-Path -LiteralPath $hosts[0] -PathType Leaf)) {
            Copy-Item -LiteralPath $hosts[0] $hostPath -Force
        }
        elseif ($hosts.Count -gt 0) {
            Set-Content -LiteralPath $hostPath "[$($hosts.Trim().TrimEnd(",") -join ",")]"
        }
        elseif ((Test-Path -LiteralPath $externalHostPath -PathType Leaf) -and $externalHostPath -ne $hostPath) {
            Copy-Item -LiteralPath $externalHostPath $hostPath -Force
        }

        [App]::new().Main($remote)
    }

    if (Test-Path -LiteralPath $trans -PathType Container) { Stop-Transcript }
    if ($loop) { Start-Sleep 60 }
}
while ($loop)

Read-Host "按回车键结束"