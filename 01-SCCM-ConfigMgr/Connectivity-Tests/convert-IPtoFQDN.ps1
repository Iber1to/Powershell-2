$ip= Get-Content .\ip.txt
foreach($item in $ip){
    $lol=ping -a $item
    $lol[1].Split(' ')[1].split('.')[0]
    }

