import subprocess
import re

docker_images = str(subprocess.run(['docker', 'images'], stdout=subprocess.PIPE).stdout, 'utf-8')
image_list = docker_images.splitlines()
for i in range(1, len(image_list)):
    image_args = re.split(r"[ ]+", image_list[i])
    image = image_args[0]+":"+ image_args[1]
    out = str(subprocess.run(['docker', 'pull', image], stdout=subprocess.PIPE).stdout,'utf-8')
    print(out)
