use inc::Module::Install;

name		'CGI-Application-Phosy';
all_from	'lib/CGI/Application/Phosy.pm';
requires	'CGI::Application' => 0;
requires	'CGI::Application::Plugin::HTCompiled' => 0;
requires	'CGI::Application::Plugin::Config::Simple' => 0;
requires	'File::Spec' => 0;
requires	'File::Basename' => 0;
requires	'File::Path' => 0;
requires	'MIME::Types' => 0;
requires	'Image::ExifTool' => 0;
requires	'Image::Magick' => 0;

install_share;

WriteAll;
