param($target)
$ip=$target.split("@")[1]
ssh-keygen -f "C:\Users\alpha\.ssh\known_hosts" -R "$ip"
scp v2ray.sh ${target}:~/
ssh -o StrictHostKeyChecking=no $target "curl -LO https://raw.githubusercontent.com/zhiwenliang/scripts/main/vps/v2ray.sh && bash ~/v2ray.sh"
