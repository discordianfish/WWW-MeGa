#!/usr/bin/perl -w
use strict;

use CGI::Application::Phosy;
use File::ShareDir;

my $share = File::ShareDir::module_dir('CGI::Application::Phosy');

my $webapp = CGI::Application::Phosy->new
(
	PARAMS => { config => '/var/www/phosy.conf' },
	TMPL_PATH => "$share/templates/default"
);
$webapp->run();
