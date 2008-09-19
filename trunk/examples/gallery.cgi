#!/usr/bin/perl -w
use strict;

use WWW::MeGa;
use File::ShareDir;

my $share = File::ShareDir::module_dir('WWW::MeGa');

my $webapp = WWW::MeGa->new
(
	PARAMS => { config => '/var/www/phosy.conf' },
	TMPL_PATH => "$share/templates/default"
);
$webapp->run();
