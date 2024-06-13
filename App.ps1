Class App {
    [void] Main() {
        $this.Welcome()
        $this.WriteResult($this.CreateJobs($this.GetHostPath()))
    }

    hidden [void] Welcome() {
        Clear-Host
        Write-Host "Console HostChecker 启动!" -ForegroundColor Red
    }

    hidden [string] GetHostPath() {
        [string] $hostPath = Join-Path $PSScriptRoot "Cealing-Host.json"

        if (Test-Path $hostPath) { return $hostPath }
        else {
            while ($true) {
                hostPath = Read-Host "输入 Cealing-Host.json 文件路径"

                if (Test-Path $hostPath) { return $hostPath }
                else { Write-Host "文件不存在" }
            }
        }

        throw
    }

    hidden [object[]] CreateJobs([string] $hostPath) {
        [object[]] $testJobs = @()

        foreach ($hostRule in Get-Content $hostPath -Raw | ConvertFrom-Json) {
            $testJobs += Start-ThreadJob {
                param ($hostRule)

                Write-Host "$($hostRule[2]): $((Test-Connection $hostRule[2] -TcpPort ($hostRule[1] -eq [string]::Empty ? 80 : 443) -Count 1 -IPv4) ? "成功" : "失败 ($($hostRule[0]))")"
            } -ArgumentList (, $hostRule)
        }

        return $testJobs
    }

    hidden [void] WriteResult([object[]] $testJobs) {
        while ($testJobs.State -ne "Completed") {
            foreach ($testResult in Receive-Job $testJobs) { Write-Host $testResult }
        }

        foreach ($testResult in Receive-Job $testJobs -Wait -AutoRemoveJob) { Write-Host $testResult }
    }
}