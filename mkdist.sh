#!/bin/sh
perl Makefile.PL && make test && make dist && make clean
rm Makefile.old
