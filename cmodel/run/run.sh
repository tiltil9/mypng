#!/bin/bash
g++ ../src/mypng.cpp         \
    ../src/mypng_parse.cpp   \
    ../src/mypng_chunk.cpp   \
    ../src/mypng_filter.cpp  \
    ../src/mypng_deflate.cpp \
    ../src/mypng_dump.cpp -o mypng

#          file_name                       width      height
LIST_INFO=(
            AlphaBall                       256       256             
            AlphaEdge                       256       256
            black817-480x360-3.5            480       360
            globe-scene-fish-bowl-pngcrush  393       501
            imgcomp-440x330                 440       330
            test                            512       512
)
PATH_RGBA_ANCHOR="./pic_rgba_anchor"
PATH_RGBA="./pic_rgba"
PATH_PNG="./pic_png"

# main loop
cnt=0
num=${#LIST_INFO[*]}
while [ $cnt -lt $num ]
do
  # get info
  file=${LIST_INFO[$cnt]} ; cnt=$((cnt+1))
  width=${LIST_INFO[$cnt]} ; cnt=$((cnt+1))
  height=${LIST_INFO[$cnt]} ; cnt=$((cnt+1))

  echo "--------------------------------------------"
  echo "$cntFile processing  $file"

  # encode rgba to png
  ./mypng -c ./png.cfg                    \
          -i $PATH_RGBA_ANCHOR/$file.txt  \
          -o $PATH_PNG/$file.png          \
          -w $width                       \
          -h $height

  # decode png to rgba
  python3 ./png2rgba.py $PATH_PNG/$file.png $PATH_RGBA/$file.txt

  # compare rgba_anchor with rgba
  diff -q  $PATH_RGBA_ANCHOR/$file.txt $PATH_RGBA/$file.txt
done