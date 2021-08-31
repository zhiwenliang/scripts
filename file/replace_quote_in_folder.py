import os
from shutil import move
import shutil


def replce_in_folder(folder_path: str, str_old: str, str_new: str):
    file_list = []
    for home, dirs, files in os.walk(folder_path):
        for file in files:
            file_path = os.path.join(home, file)
            file_list.append(file_path)
    for file in file_list:
        replace_in_file(file, str_old, str_new)


def replace_in_file(file_old_path: str, str_old: str, str_new: str):
    file_tmp_path = file_old_path + '01'
    file_old = open(file_old_path, mode='r+', encoding='utf-8')
    file_tmp = open(file_tmp_path, mode='w+', encoding='utf-8')

    data = file_old.readlines()
    for line in data:
        new_line = replace_in_str(line, str_old, str_new)
        file_tmp.write(new_line)

    file_old.close()
    file_tmp.close()
    os.remove(file_old_path)
    os.rename(file_tmp_path, file_old_path)


def replace_in_str(all_str: str, old_str: str, new_str: str):
    new_line = all_str
    if old_str in all_str:
        new_line = all_str.replace(old_str, new_str)
    return new_line


str_old = '“'
str_new = '「'
str_old_1 = '”'
str_new_1 = '」'
replce_in_folder('./', str_old, str_new)
replce_in_folder('./', str_old_1, str_new_1)
