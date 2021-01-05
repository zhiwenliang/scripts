param($target)
$ip=$target.split("@")[1]
ssh-keygen -f "C:\Users\alpha\.ssh\known_hosts" -R "$ip"
scp v2ray.sh ${target}:~/
ssh -o StrictHostKeyChecking=no $target "sh ~/v2ray.sh"
