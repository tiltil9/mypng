#!/bin/bash

# main body
help:
	@ echo "targets:                                                                                                   "
	@ echo "  clean                                       clean all check data                                         "
	@ echo "  build                                       build mypng                                                  "
	@ echo "  run                                         build mypng and run session test                             "
	@ echo "  cat                                         cat dumped check data                                        "

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
