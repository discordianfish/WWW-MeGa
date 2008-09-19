#!/usr/bin/perl -w
use strict;
use CGI::Fast;
use WWW::MeGa;
use File::ShareDir;

my %cache;
my $share = File::ShareDir::module_dir('WWW::MeGa');
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
