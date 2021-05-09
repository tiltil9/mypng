#!/bin/bash

# main body
help:
	@ echo "targets:                                                                                                   "
	@ echo "  clean                                       clean all check data                                         "
	@ echo "  build                                       build mypng                                                  "
	@ echo "  run                                         build mypng and run session test                             "
	@ echo "  cat                                         cat dumped check data                                        "
	@ echo "  bso2png                                     generate png from bs_o.dat                                   "

clean:
	cd ./check_data ;\
	    rm -rf *.dat

build:
	./build.sh

run:
	./run.sh

cat:
	cd ./check_data ;\
	    ./cat.py

bso2png:
	cd ./check_data ;\
	    ./bso2png.py
