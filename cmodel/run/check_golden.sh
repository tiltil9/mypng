#!/bin/bash
g++ ../src/mypng.cpp -o mypng

# set const
LIST_FILE=(
            AlphaBall
            AlphaEdge
            black817-480x360-3.5
            globe-scene-fish-bowl-pngcrush
            imgcomp-440x330
            test
)
PATH_RGBA_ANCHOR="./pic_rgba_anchor"
PATH_RGBA="./pic_rgba"
PATH_PNG="./pic_png"

# main loop
cntFile=0
numFile=${#LIST_FILE[*]}
while [ $cntFile -lt $numFile ]
do
  # get file name
  file=${LIST_FILE[$cntFile]}
  echo "$cntFile processing  $file" 
  cntFile=$((cntFile + 1))

  # encode rgba to png
  ./mypng $file

  # decode png to rgba
  python3 ./png2rgba.py $PATH_PNG/$file.png $PATH_RGBA/$file.txt

  # compare rgba_anchor with rgba
  diff -q  $PATH_RGBA_ANCHOR/$file.txt $PATH_RGBA/$file.txt
done