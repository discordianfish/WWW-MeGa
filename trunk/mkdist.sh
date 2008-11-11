#!/bin/sh
perl Makefile.PL && make dist && make clean
rm Makefile.old
