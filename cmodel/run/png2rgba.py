import png
import numpy as np
import sys
import os
import hashlib

# png to rgba (width , height, r, g, b, a ...)
def png2rgba(png_file, rgba_file):
    r = png.Reader(filename=png_file)
    width, height, image_1d, info = r.read_flat()
    with open(rgba_file, "w") as fp:
        fp.write(str(width)  + "\n")
        fp.write(str(height) + "\n")
        for item in image_1d:
            fp.write("%3d\n" % item)

def getRgbaAnchor():
    # assign path 
    path_src = 'pic_png_anchor/'
    path_dst = 'pic_rgba_anchor/'

    # decode each png to rgba  & compare with anchor 
    for i, filename_png in enumerate(os.listdir(path_src)):
        # get path for each png
        print(str(i) + "  processing : " + filename_png)
        filename = filename_png.split('.png')[0]
        path_png = path_src + filename + '.png'
        path_txt = path_dst + filename + '.txt'

        # save: width height R G B A...
        png2rgba(path_png, path_txt)


def main():
    if ( len(sys.argv) == 1):
        getRgbaAnchor()
    else:
        png2rgba(sys.argv[1], sys.argv[2])


if __name__ == "__main__":
    main()