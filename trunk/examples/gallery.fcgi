#!/usr/bin/perl -w
use strict;
use CGI::Fast;
use CGI::Application::Phosy;
use File::ShareDir;

my %cache;
my $share = File::ShareDir::module_dir('CGI::Application::Phosy');
while (my $q = new CGI::Fast)
{
	my $app = CGI::Application::Phosy->new
	(
		QUERY => $q,
		PARAMS => { config => '/var/www/phosy.conf', cache => \%cache },
		TMPL_PATH => "$share/templates/default"
	);
	$app->run();
};
