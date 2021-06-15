#!/bin/bash

# main body
help:
	@ echo "targets:                                                                                                   "
	@ echo "  clean                                       clean all check data                                         "
	@ echo "  build                                       build mypng                                                  "
	@ echo "  run                                         build mypng and run session test                             "
	@ echo "  cat                                         cat dumped check data                                        "
	@ echo "  oneShot                                     clean & run & cat                                            "

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

oneShot:
	make clean ;
	make run   ;
	make cat
