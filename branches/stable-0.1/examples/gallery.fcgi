#!/usr/bin/perl -w
use strict;
use CGI::Fast;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use WWW::MeGa;

my %cache;
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


while (my $q = new CGI::Fast)
{
	my $app = WWW::MeGa->new
		(
		 QUERY => $q,
		 PARAMS => { config => '/var/www/phosy.conf', cache => \%cache },
		 TMPL_PATH => "$share/templates/default"
		);
	$app->run();
};
