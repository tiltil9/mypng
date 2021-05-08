#!/bin/bash
g++ ../src/mypng.cpp         \
    ../src/mypng_parse.cpp   \
    ../src/mypng_chunk.cpp   \
    ../src/mypng_filter.cpp  \
    ../src/mypng_deflate.cpp \
    ../src/mypng_dump.cpp    \
                               -o mypng