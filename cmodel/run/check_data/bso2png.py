#!/usr/bin/python3

import sys
import os

def writeSign(fptPng):
    fptPng.write(bytes([137, 80, 78, 71, 13, 10, 26, 10]))

def writeIHDR(fptPng, width, height, ihdr_crc32):
    # length
    fptPng.write(int(13).to_bytes(length = 4, byteorder = 'big', signed = False))
    # type
    fptPng.write(bytes([ord('I'), ord('H'), ord('D'), ord('R')]))   
    # data (width, height, bit depth, color type, compression method, filter method, interlace method)
    fptPng.write(int(width).to_bytes(length = 4, byteorder = 'big', signed = False))
    fptPng.write(int(height).to_bytes(length = 4, byteorder = 'big', signed = False))
    fptPng.write(bytes([8, 6, 0, 0, 0]))
    # crc32
    fptPng.write(bytes.fromhex(ihdr_crc32))

def writeIDAT(fptPng, zlib_length, lines, idat_crc32):
    zlib_length_int = int(zlib_length, base = 16)
    # length
    fptPng.write(zlib_length_int.to_bytes(length = 4, byteorder = 'big', signed = False))
    # type
    fptPng.write(bytes([ord('I'), ord('D'), ord('A'), ord('T')]))   
    # data (zlib)
    zlib_lines_len = len(lines) - 4
    for i in range(0, zlib_lines_len):
        if(i != zlib_lines_len - 1):
            fptPng.write(bytes.fromhex(lines[i][0:8]))
        else:
            if(zlib_length_int % 4 == 0):
                fptPng.write(bytes.fromhex(lines[i][0:8]))
            elif(zlib_length_int % 4 == 1):
                fptPng.write(bytes.fromhex(lines[i][0:2]))
            elif(zlib_length_int % 4 == 2):
                fptPng.write(bytes.fromhex(lines[i][0:4]))
            else:
                fptPng.write(bytes.fromhex(lines[i][0:6]))
    # crc32
    fptPng.write(bytes.fromhex(idat_crc32))

def writeIEND(fptPng, iend_crc32):
    # length
    fptPng.write(int(0).to_bytes(length = 4, byteorder = 'big', signed = False))
    # type
    fptPng.write(bytes([ord('I'), ord('E'), ord('N'), ord('D')]))   
    # data (none)
    # crc32
    fptPng.write(bytes.fromhex(iend_crc32))

def main():
    # check arguments
    if(len(sys.argv) != 3):
        print("Arguments error                        ")
        print("Usage:    ./bso2png.py [width] [height]")
    else:
        width  = sys.argv[1]
        height = sys.argv[2]

        # check file
        path_check_data = "./"
        file_list       = os.listdir(path_check_data)
        if 'bs_o.dat' not in file_list:
            print("File error:    bs_o.dat not found      ")
        else:
            with open('bs_o.dat', 'r') as fptBsO:
                with open('bso2png.png', 'wb') as fptPng:
                    # read file
                    lines = fptBsO.readlines()
                    zlib_length = lines[-4].strip()
                    idat_crc32  = lines[-3].strip()
                    ihdr_crc32  = lines[-2].strip()
                    iend_crc32  = lines[-1].strip()

                    # write out PNG signature
                    writeSign(fptPng)
                    # write out IHDR chunk
                    writeIHDR(fptPng, width, height, ihdr_crc32)
                    # write out IDAT chunk
                    writeIDAT(fptPng, zlib_length, lines, idat_crc32)
                    # write out IEND chunk
                    writeIEND(fptPng, iend_crc32)

if __name__ == "__main__":
    main()