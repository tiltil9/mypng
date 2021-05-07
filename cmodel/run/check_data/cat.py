#!/usr/bin/python3

import os

def main():
  path_check_data = "./"
  file_list       = os.listdir(path_check_data)
  file_list_all   = ('Wh.dat', 'Zlib.dat', 'Lz77.dat', 'Adler32.dat', 'Crc32.dat', 'ZlibBs.dat')

  # crc32_i = wh + zlib
  if 'Wh.dat' in file_list and 'Zlib.dat' in file_list:
    with open('crc32_i.dat', 'w') as fptCrc32:
      with open('Wh.dat', 'r') as fptWh:
        fptCrc32.writelines(fptWh.readlines())
      with open('Zlib.dat', 'r') as fptZlib:
        fptCrc32.writelines(fptZlib.readlines())

  # bs_i = lz77 + adler32 + crc32
  if 'Lz77.dat' in file_list and 'Adler32.dat' in file_list and 'Crc32.dat' in file_list:
    with open('bs_i.dat', 'w') as fptBsI:
      with open('Lz77.dat', 'r') as fptLz77:
        fptBsI.writelines(fptLz77.readlines())
      with open('Adler32.dat', 'r') as fptAdler32:
        fptBsI.writelines(fptAdler32.readlines())
      with open('Crc32.dat', 'r') as fptCrc32:
        fptBsI.writelines(fptCrc32.readlines())

  # bs_o = zlib + adler32 + crc32
  if 'ZlibBs.dat' in file_list and 'Adler32.dat' in file_list and 'Crc32.dat' in file_list:
    with open('bs_o.dat', 'w') as fptBsO:
      with open('ZlibBs.dat', 'r') as fptZlibBs:
        fptBsO.writelines(fptZlibBs.readlines())
      with open('Adler32.dat', 'r') as fptAdler32:
        fptBsO.writelines(fptAdler32.readlines())
      with open('Crc32.dat', 'r') as fptCrc32:
        fptBsO.writelines(fptCrc32.readlines())


if __name__ == "__main__":
    main()