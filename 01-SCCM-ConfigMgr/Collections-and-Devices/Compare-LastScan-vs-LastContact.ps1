$test= Get-CMDevice -Name WKSAMPLE01
$test.LastActiveTime
($test.LastHardwareScan).AddDays(8)
if (($test.LastHardwareScan).AddDays(8) -ilt $test.LastActiveTime)
    {
        Write-Host "El ultimo scan de hardware de $($test.name) con fecha: $(($test.LastHardwareScan).AddDays(8)) es menor que la ultima vez que la maquina conecto $($test.LastActiveTime)  "
    }