#!/usr/bin/perl -w
use strict;
use FindBin qw($RealBin);

use if -e "$RealBin/../Makefile.PL", lib => "$RealBin/../lib";
use WWW::MeGa;

my $webapp = WWW::MeGa->new;
$webapp->run;
