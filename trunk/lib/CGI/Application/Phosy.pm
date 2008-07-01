package CGI::Application::Phosy;

=head1 NAME
CGI::Application::Phosy - A media gallery

=head1 SYNOPSIS
=begin perl

my $webapp = CGI::Application::Phosy->new
(
	PARAMS => { config => /path/to/your/config }
);
$webapp->run;

=end

Minimal config:
=begin text

root /path/to/your/pictures

=end


=head1 DESCRIPTION
CGI::Application::Phosy is a web based media browser. It should
be run from mod_perl or FastCGI (see examples/gallery.fcgi) because
it uses some runtime caching.

Atm every file will be delievered by the CGI itself. So you don't need
to care about setting up picture/thumb dirs.

=head2 FEATURES=
==over
=item *
on-the-fly image resizing (and orientation tag based autorotating)
=item *
video thumbnails
=item *
displays text files
=item *
reads exif tag
=item *
templating with <HTML::Template::Compiled>
=back

=head1 AUTHOR
Johannes 'fish' Ziemke <fish-code@freigeist.org>

=head1 SEE ALSO
<CGI::Application>

=cut
use CGI::Application;
use File::Spec;
use Scalar::Util;

use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

use CGI::Application::Plugin::Config::Simple;

use CGI::Application::Phosy::Item;

use strict;
use warnings;

our $VERSION = '0.01';
sub setup
{
	my $self = shift;
	$self->{PathPattern} = "[^-,()'.\/ _0-9A-Za-z\x80-\xff\[\]]";
	$self->config_file($self->param('config')) or die "no config set. use i.e. PARAMS => { config => '/path/to/config.conf' }";

	$self->{sizes} = $self->config_param('sizes') || [ 120, 600, 800 ];
	$self->config_param('cache', '/tmp/phosy') unless $self->config_param('cache');
	$self->config_param('album_thumb', 'THUMBNAIL') unless $self->config_param('album_thumb');
	$self->config_param('icons', 'icons/') unless $self->config_param('icons');


	$self->{cache} = $self->param('cache');

	$self->run_modes
	(
		view => 'view_path',
		image => 'view_image',
		original => 'view_original',
	);
	$self->start_mode('view');
	$self->error_mode('view_error');

	#die "PARAMS => { gallery_root => '/path/to/gallery' } net set" unless defined $self->param('gallery_root');
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

=head2 parameter parsing functions

Caution: these functions parse the user input

=cut



=head3 saneReq
returns a sanitized var
=cut
sub saneReq
{
	my $self = shift;
	my $param = shift;
	my $pattern = shift || $self->{PathPattern};
	my $req = $self->query->param($param) or return undef;
	$req =~ s/$pattern//g;
	return $req;
}

=head3
returns the given path, dies if no path specified
=cut
sub fileReq($)
{
	my $self = shift;
	my $path = $self->saneReq('path') or die "want file, got nothing";
	return $path
}

=head3
returns the given path
=cut
sub albumReq
{
	my $self = shift;
	my $path = $self->saneReq('path') || '';
	return $path;
}

=head3
returns a number representing a size (index for @sizes)
=cut
sub sizeReq
{
	my $self = shift;
	my $size = $self->saneReq('size', '[^0-9]') or return 0; #return @{$self->{sizes}}[0];
	die "no size '$size'" unless $self->{sizes}->[$size];
	return $size;
}


=head2

runmodes

=cut

=head3 view_image
returns a thumbnail
=cut
sub view_image
{
	my $self = shift;
	my $path = $self->fileReq;

	my $size = $self->{sizes}->[$self->sizeReq];

	my $item = CGI::Application::Phosy::Item->new($path,$self->config(),$self->{cache});
	return $self->binary( $item->thumbnail($size) );
}

=head3 view_original
view original file
=cut
sub view_original
{
	my $self = shift;
	my $path = $self->fileReq;

	my $item = CGI::Application::Phosy::Item->new($path,$self->config(),$self->{cache});
	return $self->binary($item->{path}, $item->original);
}

sub view_path
{
	my $self = shift;
	use Data::Dumper;
	my $path = $self->albumReq;
	my $size_idx = $self->sizeReq;
	my %sizes =
	(
		SIZE => $size_idx,
		SIZE_IN => $size_idx+1,
		SIZE_OUT => $size_idx-1
	);

	my $item = CGI::Application::Phosy::Item->new($path,$self->config(),$self->{cache});

	my @path_e = File::Spec->splitdir($path);
	my $parent = File::Spec->catdir(@path_e[0 .. @path_e-2]); # bei file: album des files, bei folder: enthaltener folder


	my $t;
	if (Scalar::Util::blessed($item) eq 'CGI::Application::Phosy::Item::Folder')
	{
		$t = $self->load_tmpl('album.tmpl', die_on_bad_params=>0, global_vars=>1);
		my @items = map { (CGI::Application::Phosy::Item->new($_,$self->config(),$self->{cache}))->data } $item->list;
		$t->param(PARENT => $parent, %sizes, ITEMS => \@items, CONFIG => $self->config->vars);

	} else
	{
		$t = $self->load_tmpl('image.tmpl', die_on_bad_params=>0, global_vars=>1);
		$t->param(PARENT => $parent, %sizes, %{ $item->data }, CONFIG => $self->config->vars);
	}

	return $t->output;
}




sub binary
{
	my $self = shift;
	my $path = shift or die "no key found"; # key for cache
	my $data = shift or die "no data found";
	my $file = File::Basename::basename $path;
	my $mime = $self->{cache}->{mime}->{$path} if $path;

	unless ($mime)
	{
		#use File::MMagic;
		#my $mm = File::MMagic->new($self->config_param('mime-magic'));
		#$mime = $mm->checktype_contents($data);
		use MIME::Types;
		my $mt = MIME::Types->new();
		warn "trying to guess mime type for $path";
		$mime = $mt->mimeTypeOf($path) or die "$!";

		$self->{cache}->{mime}->{$path} = $mime if $path;
	} 
	warn "mime type for $path: $mime";
	$self->header_props ({-type => $mime, -Content_length => -s $path });
	return $data;
}

1
