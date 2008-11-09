use strict;
use Test::Simple tests => 7;
use lib './lib';

ok(File::ShareDir::module_dir('WWW::MeGa'), "share dir is " . File::ShareDir::module_dir('WWW::MeGa'));
use WWW::MeGa;

ok(1, 'use WWW::MeGa');

my $cgi;
ok(
	$cgi = WWW::MeGa->new
	(
		PARAMS =>
		{
			config => 'examples/gallery.conf'
		},
		TMPL_PATH => 'share/templates/default'
	),
	'instanced'
);

ok($cgi->run, 'run');

ok($cgi->view_path, 'view path w/o path');


ok(sub
{
	$cgi->query->param(-name=>'path', value =>'/bine.jpg');
	$cgi->view_path;
	$cgi->run;
}, 'view path "/bine.jpg"');

ok(sub
{
	$cgi->query->param(-name=>'path', value =>'/moeve.jpg');
	$cgi->query->param(-name=>'rm', value =>'image');
	$cgi->query->param(-name=>'size', value =>1);
	$cgi->view_path;
	$cgi->run;
}, 'view image "/moeve.jpg" (involves thumb generating)');
