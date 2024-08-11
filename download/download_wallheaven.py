import re
import os
import time
import shutil
import requests
from PIL import Image
from lxml import etree
from queue import Queue
from threading import Thread


class DownloadPicture:
    """
    This class was created to download pictures from 'https://wallheaven.cc'
    """

    def __init__(self, _s: str, _path: str, _header: dict, _q: Queue):
        """

        :param _s: The picture's English name that will be searched
        :param _path: The path that save downloaded pictures
        :param _header: The header
        :param _q: The queue to hold the links
        """
        self.__s = _s
        self.__path = _path
        self.__header = _header
        self.__q = _q

    def __get_count(self) -> int:
        """
        Parsed the website and show its total number of picture and return its pages

        :return: int
        """
        _url = f"https://wallhaven.cc/search?q={self.__s}"
        _request = requests.get(_url, headers=self.__header).text
        _html = etree.HTML(_request)
        _tree = _html.xpath("//*[@id='main']/header/h1/text()")
        _str_num = re.findall('[0-9]', _tree[0])
        _str = "".join(_str_num)
        _num = int(_str) // 24 + 1 if int(_str) % 24 != 0 else int(_str) // 24
        print(f"[ + ] 为您找到{_str}张共{_num}页关于{self.__s}的壁纸")
        num_will_be_input = str(input("请输入想要下载的页数(留空则全部下载):"))
        if num_will_be_input == "":
            return _num
        else:
            return int(num_will_be_input)

    def __parsing(self, _url: str, _condition_by: str) -> list:
        """
        Parsing the given url of website 'https://wallheaven.cc'

        :param _url: The url that will be parsed,its type should be str
        :param _condition_by: Rules for parsing url,its type should be str
        :return: list
        """
        _request = requests.get(_url, headers=self.__header).text
        _html = etree.HTML(_request)
        _tree = _html.xpath(_condition_by)
        return _tree

    def classify_images(self) -> None:
        """
        This method will classify pictures that was downloaded
        :return: None
        """
        for files in os.listdir(self.__path):
            paths = os.path.join(self.__path, files)
            while os.path.isfile(paths):
                with Image.open(paths) as img:
                    width = img.width
                    if 1280 <= width < 1920:
                        width = "720"
                    elif 1920 <= width < 2560:
                        width = "1K"
                    elif 2560 <= width < 3840:
                        width = "2K"
                    elif 3840 <= width < 5120:
                        width = "4K"
                    elif 5120 <= width < 6114:
                        width = "5K"
                    elif 6114 <= width < 7168:
                        width = "6K"
                    elif 7168 <= width < 7680:
                        width = "7K"
                    elif 7680 <= width < 10000:
                        width = "8K"
                try:
                    shutil.move(f"{paths}", f"{self.__path}{width}/{os.path.split(paths)[1]}")
                except FileNotFoundError:
                    try:
                        os.mkdir(f"{self.__path}{width}")
                    except FileExistsError:
                        pass

    def search_pic_by_name(self) -> None:
        """
        Enter picture's English name and search it
        then put the results into the Queue

        :return: None
        """

        count = self.__get_count()
        for number in range(count):
            url = f"https://wallhaven.cc/search?q={self.__s}&page={number + 1}"
            parsing_preview = "//*/div//a[@class='preview']//@href"
            parsing_pic_urls = "//*[@id='wallpaper']/@src"
            for preview_urls in self.__parsing(url, parsing_preview):
                for pictures in self.__parsing(preview_urls, parsing_pic_urls):
                    self.__q.put(pictures)

    def download(self) -> None:
        """
        Download pictures and save it to the path which was given

        :return: None
        """

        count = 0
        while True:
            name = self.__q.get()
            _s = name.rfind("/")
            time.sleep(1)
            pic_requests = requests.get(name, headers=self.__header).content
            try:
                with open(f"{self.__path}/{name[_s + 1::]}", 'wb') as f:
                    f.write(pic_requests)
                    print(f"[ + ] Downloaded: [ {count + 1} ] {name[_s + 1::]}")
                    count += 1
                    if self.__q.empty():
                        break
            except FileNotFoundError:
                os.mkdir(self.__path)


def main():
    q = Queue()
    my_dir_path = "./myDownloadPicture/"
    user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) " \
                 "Chrome/88.0.4324.190 Safari/537.36 "
    head = {"user-agent": user_agent}
    pic_name = str(input("请输入图片名字(英文名称):"))
    downloader = DownloadPicture(pic_name, my_dir_path, head, q)
    t1 = Thread(target=downloader.search_pic_by_name)
    t2 = Thread(target=downloader.download)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    downloader.classify_images()


if __name__ == '__main__':
    main()
