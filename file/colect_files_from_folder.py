import os
import shutil
from typing import List


def main(source_dir: str, des_dir: str, ext: str):
    files = list_file_with_ext(source_dir, ext)
    for file in files:
        shutil.copy(file, des_dir)


# List all music files with path. Get file type by extension name.
def list_file_with_ext(file_path: str, ext_list: List[int]):
    result = []
    for home, dirs, files in os.walk(file_path):
        for file in files:
            if (os.path.splitext(file)[1] in ext_list):
                file_path = os.path.join(home, file)
                result.append(file_path)

    return result


source_dir = './'
des_dir = './0_new_folder'
ext_list = ['.wav', '.mp3', '.flac', '.ape']
os.makedirs(des_dir)
main(source_dir, des_dir, ext_list)
