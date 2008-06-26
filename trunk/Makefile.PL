use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME		=> 'CGI::Application::Phosy',
	VERSION_FROM	=> 'lib/CGI/Application/Phosy.pm',
	PREREQ_PM	=>
	{
		'CGI::Application' => 0,
		'CGI::Application::Plugin::HTCompiled' => 0,
		'CGI::Application::Plugin::Config::Simple' => 0,
		'File::Spec' => 0,
		'File::Basename' => 0,
		'File::Path' => 0,
		'MIME::Types' => 0,
		'Image::ExifTool' => 0,
		'Image::Magick' => 0,
	}
);
