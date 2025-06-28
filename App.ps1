Class App {
    [void] Main() {
        $this.Welcome()
        $this.WriteTestResult($this.CreateTestJobs($this.GetHostPath()))
        $this.Closing()
    }

    hidden [void] Welcome() {
        Clear-Host
        Write-Host "Console HostChecker 启动!" -ForegroundColor Red
    }

    hidden [string] GetHostPath() {
        [string] $hostPath = Join-Path $PSScriptRoot "Cealing-Host.json"

        while (-not (Test-Path $hostPath -PathType Leaf)) { $hostPath = (Read-Host "输入 Cealing-Host.json 文件路径").Trim("""") }

        return $hostPath
    }

    hidden [array] CreateTestJobs([string] $hostPath) {
        [array] $testJobs = @()

        foreach ($hostRule in Get-Content $hostPath -Raw | ConvertFrom-Json) {
            $testJobs += Start-ThreadJob {
                param ([array] $hostRule)

                if ([string]::IsNullOrWhiteSpace($hostRule[2])) { continue }

                [string] $testResult = (Test-Connection $hostRule[2] -TcpPort 443 -Count 1) ? "成功" : "失败 ($($hostRule[0]))"

                Write-Host "$($hostRule[2]): $testResult"
            } -ArgumentList (, $hostRule)
        }

        return $testJobs
    }

    hidden [void] WriteTestResult([array] $testJobs) {
        while ($testJobs.State -ne "Completed") {
            foreach ($testOutput in Receive-Job $testJobs) { Write-Host $testOutput }
        }

        foreach ($testOutput in Receive-Job $testJobs -Wait -AutoRemoveJob) { Write-Host $testOutput }
    }

    hidden [void] Closing() {
        Write-Host "测试结果仅供参考" -ForegroundColor Red
    }
}