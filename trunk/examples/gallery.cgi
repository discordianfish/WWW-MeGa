#!/usr/bin/perl -w
use strict;
use FindBin qw($RealBin);

my $share;

if ( -e "$RealBin/../Makefile.PL")
{
	$share = "$RealBin/../share";
	use lib "$RealBin/../lib";
} else
{
	use File::ShareDir;
	$share = File::ShareDir::module_dir('WWW::MeGa');
}

use WWW::MeGa;


my $webapp = WWW::MeGa->new
(
	PARAMS => { config => '/var/www/gallery.conf' },
	TMPL_PATH => "$share/templates/default"
);
$webapp->run;
