import os
import shutil


def main(sourceDir, desDir, ext):
    try:
        files = listFileWithExt(sourceDir, ext)
        for file in files:
            shutil.copy(file, desDir)
    except Exception:
        print("Some errors occur!")


# List all music files with path. Get file type by extension name.
def listFileWithExt(filePath, extList):
    result = []
    for home, dirs, files in os.walk(filePath):
        for file in files:
            if (os.path.splitext(file)[1] in extList):
                filePath = os.path.join(home, file)
                result.append(filePath)

    return result


sourceDir = './'
desDir = './0_newFolder'
extList = ['.wav', '.mp3', '.flac', '.ape']
os.makedirs(desDir)
main(sourceDir, desDir, extList)
