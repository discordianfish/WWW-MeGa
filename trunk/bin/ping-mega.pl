#!/usr/bin/perl -w
# $Id$

use strict;
use File::Find;
use File::Spec;
use FindBin qw($RealBin);

use constant 'URL_FS' => "%s?path=%s;size=%s\n";
use constant 'SIZES' => ( 0, 1, 2 );

use if -e "$RealBin/../Makefile.PL", lib => "$RealBin/../lib";

use WWW::MeGa;

my $url = shift;
my $in = shift;

die "path '$in' specified but invalid: $!" if $in and not -e $in;

my $ROOT = ($in and -d $in) ? $in : WWW::MeGa->new(PARAMS => { config => $in })->config->param('root');

find \&ping, $ROOT;

### 
sub ping
{
	my $abs = $File::Find::name;
	return unless -f $abs;
	my $rel = File::Spec->abs2rel($abs, $ROOT);
	printf URL_FS, $url, $rel, $_ for (SIZES);
}
