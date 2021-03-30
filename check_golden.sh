#!/bin/bash
g++ mypng.cpp -o mypng
./mypng
diff -q ./test.png golden/test.png