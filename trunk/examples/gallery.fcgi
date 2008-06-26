#!/usr/bin/perl -w
use strict;
use CGI::Fast;
use lib '../lib/';
use CGI::Application::Phosy;

my %cache;
while (my $q = new CGI::Fast)
{
	my $app = CGI::Application::Phosy->new
	(
		QUERY => $q,
		PARAMS =>
		{
			config => '/data/Code/projects/CGI-Application-Phosy/trunk/examples/gallery.conf',
			cache => \%cache,
		},
		TMPL_PATH => '/data/Code/projects/CGI-Application-Phosy/trunk/share/templates/default'
	);
	$app->run();
};
