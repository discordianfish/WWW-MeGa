package WWW::MeGa;
use 5.6.0;
use strict;
use warnings;

=head1 NAME

WWW::MeGa - A MediaGallery

=head1 SYNOPSIS

 use WWW::MeGa;
 my $webapp = WWW::MeGa->new
 $webapp->run;

=head1 DESCRIPTION

WWW::MeGa is a web based media browser. It should
be run from mod_perl or FastCGI (see examples/gallery.fcgi) because
it uses some runtime caching.

Every file will be delievered by the CGI itself. So you don't have
to care about setting up picture/thumb dirs.


=head1 FEATURES

=over

=item * on-the-fly image resizing (and orientation tag based autorotating)

=item * video thumbnails

=item * displays text files

=item * reads exif tag

=item * templating with L<HTML::Template::Compiled>

=back

=head1 CONFIG
L<WWW::MeGa> uses L<CGI::Application::Plugin::Config::Simple> for config handling.
You can specify the path to a (writable) config file in the new methode of WWW::MeGa:

   my $gallery = WWW::MeGa->new(PARAMS => { config => '/path/to/gallery.conf' })

It defaults to $RealBin/gallery.conf, see L<RealBin> for more info.
After the first run it will create a config containing the defaults.


=head2 Parameters

=head3 root

Path to your images


=head3 cache

Path where to store the thumbnails

=head3 thumb-type

Type of the thumbnails.
L<WWW::MeGa> uses L<Image::Magick> for generating thumbnails.
See C<convert -list format> for file types supported by you ImageMagick
installation.


=head3 sizes

A array of valid "thumbnail"/resized image sizes, defaults to
[ 120, 600, 800 ].
The CGI parameter C<size> is the index to that array.


=head3 debug

If set to 1, enabled debugging to your servers error log.


=head3 album_thumb

Specify the name of the image which will be used as a thumbnail for the
containing album, defaults to THUMBNAIL.

So if you want to have the image C<foo.jpg> be the thumbnail for the album C<bar>, copy it to C<bar/THUMBNAIL> (or use a symlink)


=head3 icons and templates

Path to the icons and templates, defaults to C<icons/> in the module's share dir as defined by L<Module::Install> and L<File::ShareDir>


=head1 METHODES

=cut

use CGI::Application;
use File::Spec;
use Scalar::Util;
use File::ShareDir;
use FindBin qw($RealBin);

use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

use CGI::Application::Plugin::Config::Simple;
use CGI::Application::Plugin::Stream (qw/stream_file/);

use WWW::MeGa::Item;

use Carp;

our $VERSION = '0.09_3';
sub setup
{
	my $self = shift;
	$self->{PathPattern} = "[^-,()'.\/ _0-9A-Za-z\x80-\xff\[\]]";
	
	my $share = eval { File::ShareDir::module_dir('WWW::MeGa') } || "$RealBin/../share";

	my $config = $self->config_file($self->param('config') || "$RealBin/gallery.conf");

	my %default_config =
	(
		'sizes' => [ 120, 600, 800 ],
		'cache' => '/tmp/www-mega',
		'album_thumb' => 'THUMBNAIL',
		'thumb-type' => 'png',
		'root' => File::Spec->catdir($share, 'images'),
		'debug' => 0,
		'icons' => File::Spec->catdir($share, 'icons'),
		'templates' => File::Spec->catdir($share, 'templates', 'default')
	);

	unless ( -e $config )
	{
		warn "config '$config' not found, creating default config";
		my $cfg = new Config::Simple(syntax=>'simple');
		foreach my $k (keys %default_config)
		{
			$cfg->param($k, $default_config{$k})
		}

		warn "saving $config";
		$cfg->write($config) or croak "could not create config '$config': $!";
	}

	$self->config_file($config) or croak "could not load config '$config': $!";

	foreach my $k (keys %default_config)
	{
		next if $self->config_param($k);
		$self->config_param($k, $default_config{$k});
	}

	croak $self->config_param('root') . " is no directory" unless -d $self->config_param('root');

	$self->tmpl_path($self->config_param('templates'));

	$self->{sizes} = $self->config_param('sizes');

	$self->{cache} = $self->param('cache');

	$self->run_modes
	(
		view => 'view_path',
		image => 'view_image',
		original => 'view_original',
	);
	$self->start_mode('view');
	$self->error_mode('view_error');
	return;
}

sub view_error
{
	my $self = shift;
	my $error = shift;
	warn "ERROR: $error";
	my $t = $self->load_tmpl('error.tmpl', die_on_bad_params=>0, global_vars=>1);
	$self->header_props ({-status => 404 });
	$t->param(ERROR => $error);
	return $t->output;
}

sub saneReq
{
	my $self = shift;
	my $param = shift;
	my $pattern = shift || $self->{PathPattern};
	my $req = $self->query->param($param) or return;
	$req =~ s/$pattern//g;
	return $req;
}

sub fileReq
{
	my $self = shift;
	my $path = $self->saneReq('path') or die "want file, got nothing";
	return $path
}

sub pathReq
{
	my $self = shift;
	my $path = $self->saneReq('path') || '';
	return $path;
}

sub sizeReq
{
	my $self = shift;
	my $size = $self->saneReq('size', '[^0-9]') or return 0; #return @{$self->{sizes}}[0];
	die "no size '$size'" unless $self->{sizes}->[$size];
	return $size;
}


=head2 runmodes

the public runmodes, accessable via the C<rm> parameter

=head3 image

shows a thumbnail

=cut

sub view_image
{
	my $self = shift;
	my $path = $self->fileReq;

	my $size = $self->{sizes}->[$self->sizeReq];

	my $item = WWW::MeGa::Item->new($path,$self->config(),$self->{cache});

	return $self->binary($item, $size);
}


=head3 original

shows the original file

=cut

sub view_original
{
	my $self = shift;
	my $path = $self->fileReq;

	my $item = WWW::MeGa::Item->new($path,$self->config(),$self->{cache});
	return $self->binary($item);
}


=head3 view

shows a album/folder

=cut

sub view_path
{
	my $self = shift;
	my $path = $self->pathReq;
	my $size_idx = $self->sizeReq;
	my $off;
	{
		my $tmp = $self->query->param('off');
		$off = $tmp if $tmp && ($tmp eq 'next' || $tmp eq 'prev');
	}

	my %sizes =
	(
		SIZE => $size_idx,
		SIZE_IN => $size_idx+1,
		SIZE_OUT => $size_idx-1
	);

	my @path_e = File::Spec->splitdir($path);
	my $parent = File::Spec->catdir(@path_e[0 .. @path_e-2]); # bei file: album des files, bei folder: enthaltener folder

	if ($off)
	{
		my $pitem = WWW::MeGa::Item->new($parent,$self->config,$self->{cache}); # should be a folder in every case;
		my @n = $pitem->neighbours($path, $off);
		$path = $off eq 'next' ? $n[1] : $n[0];
	}

	my $item = WWW::MeGa::Item->new($path,$self->config,$self->{cache});



	my $t;
	if (Scalar::Util::blessed($item) eq 'WWW::MeGa::Item::Folder')
	{
		$t = $self->load_tmpl('album.tmpl', die_on_bad_params=>0, global_vars=>1);
		my @items = map { (WWW::MeGa::Item->new($_,$self->config(),$self->{cache}))->data } $item->list;
		$t->param(PARENT => $parent, %sizes, %{ $item->data }, ITEMS => \@items, CONFIG => { $self->config->vars });

	} else
	{
		$t = $self->load_tmpl('image.tmpl', die_on_bad_params=>0, global_vars=>1);
		my %hash = (PARENT => $parent, %sizes, %{ $item->data }, CONFIG => { $self->config->vars });
		$t->param(%hash);
	}

	return $t->output;
}




sub binary
{
	my $self = shift;
	my $item = shift;
	my $size = shift;


	if ($size)
	{
		# $self->header_add( -'Content-disposition' => 'inline' );
		return $self->stream_file($item->thumbnail($size)) ? undef : $self->error_mode;
	} else
	{
		# $self->header_add( -attachment => $item->{file} );
		return $self->stream_file($item->original) ? undef : $self->error_mode;
	}
}

=head1 COPYRIGHT

Copyright 2008 by Johannes 'fish' Ziemke.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<CGI::Application>


=head1 AUTHOR

Johannes 'fish' Ziemke <my nickname at cpan org>


=cut

1;
