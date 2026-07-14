Class App {
    [void] Main([bool] $remote) {
        $this.Welcome()
        $this.WriteTestResult($remote ? $this.CreateCheckJobs($this.GetHostPath()) : $this.CreateTestJobs($this.GetHostPath()))
        $this.Closing()
    }

    hidden [void] Welcome() {
        try { Clear-Host -ErrorAction Stop } catch { Write-Verbose $_ }
        Write-Host "Console HostChecker 启动!" -ForegroundColor Red
    }

    hidden [string] GetHostPath() {
        [string] $hostPath = Join-Path $PSScriptRoot "Cealing-Host.json"

        while (-not (Test-Path -LiteralPath $hostPath -PathType Leaf)) { $hostPath = (Read-Host "输入 Cealing-Host.json 文件路径").Trim("""") }

        return $hostPath
    }

    hidden [array] CreateCheckJobs([string] $hostPath) {
        return @(Start-ThreadJob {
            param ([string] $hostPath)

            [hashtable] $seenTargets = @{}
            [string[]] $hostTargets = @(
                foreach ($hostRule in ConvertFrom-Json (Get-Content -LiteralPath $hostPath -Raw)) {
                    if ([string]::IsNullOrWhiteSpace($hostRule[2]) -or $seenTargets.ContainsKey($hostRule[2])) { continue }
                    $seenTargets[$hostRule[2]] = $true
                    $hostRule[2]
                }
            )

            if ($hostTargets.Count -eq 0) { return }

            if (-not (Get-Module -ListAvailable "Console-CensorChecker")) {
                Install-PSResource "Console-CensorChecker" -TrustRepository -ErrorAction Stop
            }

            Import-Module "Console-CensorChecker" -ErrorAction Stop

            Invoke-Check $hostTargets | ForEach-Object {
                "$($_.Target): $($_.Latency -eq [int]::MaxValue ? "超时" : "$($_.Latency) ms")"
            }
        } -ArgumentList $hostPath)
    }

    hidden [array] CreateTestJobs([string] $hostPath) {
        return @(foreach ($hostRule in ConvertFrom-Json (Get-Content -LiteralPath $hostPath -Raw)) {
            Start-ThreadJob {
                param ([array] $hostRule)

                if ([string]::IsNullOrWhiteSpace($hostRule[2])) { continue }

                [string] $testResult = (Test-Connection $hostRule[2] -TcpPort 443 -Count 1) ? "成功" : "失败 ($($hostRule[0]))"

                "$($hostRule[2]): $testResult"
            } -ArgumentList (, $hostRule)
        })
    }

    hidden [void] WriteTestResult([array] $testJobs) {
        while ($testJobs.State -eq "Running" -or $testJobs.State -eq "NotStarted") {
            foreach ($testOutput in Receive-Job $testJobs) { Write-Host $testOutput }
        }

        foreach ($testOutput in Receive-Job $testJobs -Wait -AutoRemoveJob) { Write-Host $testOutput }
    }

    hidden [void] Closing() {
        Write-Host "测试结果仅供参考" -ForegroundColor Red
    }
}
