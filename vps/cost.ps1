param($target)
$result = ssh -o stricthostkeychecking=no $target "cat /proc/uptime"
$running_seconds = [int]($result.split(" ")[0])
$running_hours = [math]::Floor($running_seconds / 3600)
$m = [math]::Floor(($running_seconds / 60) % 60)
Write-Output "running time: $running_hours : $m"
$cost = ([double]([string](($running_hours + 1) * 3.5 / 672)).substring(0, 4)) + 0.01
Write-Output "current cost: $ $cost"