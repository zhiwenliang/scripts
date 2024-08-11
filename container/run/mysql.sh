podman run -itd --name mysql-demo -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql -v /home/alpha/source/db/mysql/data:/var/lib/mysql mysql
