#!/usr/bin/perl -w
use strict;

use lib '../lib/';
use CGI::Application::Phosy;

#our @ISA = qw(CGI::Application);

my $webapp = CGI::Application::Phosy->new
(
	PARAMS =>
	{
		config => '/data/Code/projects/CGI::Application::Phosy/trunk/examples/gallery.conf'
	},
	TMPL_PATH => '/data/Code/projects/CGI::Application::Phosy/trunk/share/templates/default'
);
$webapp->run();
