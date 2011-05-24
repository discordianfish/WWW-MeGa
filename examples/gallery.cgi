#!/usr/bin/env perl
# $Id$

use strict;
use warnings;
use FindBin qw($RealBin);

use if -e "$RealBin/../Makefile.PL", lib => "$RealBin/../lib";
use WWW::MeGa;

my $webapp = WWW::MeGa->new;
$webapp->run;
