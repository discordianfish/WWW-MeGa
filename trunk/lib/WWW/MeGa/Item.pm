package WWW::MeGa::Item;
use strict;
use warnings;

=head1 NAME

WWW::MeGa::Item - Representing a item in L<WWW::MeGa>

=head1 SYNOPSIS

 use WWW::MeGa::Item;
 my $item = WWW::MeGa::Item->new('some/file.jpg', $config, $cache);
 print $item->thumbnail(1);

=head1 DESCRIPTION

WWW::MeGa::Item represents a "item" in L<WWW::MeGa>.
It get instanced by passed a relative path to a arbitrary file and return on of the following specific object based on the mime type:

=over

=item * L<WWW::MeGa::Item::Audio>

=item * L<WWW::MeGa::Item::Folder> - represents a album

=item * L<WWW::MeGa::Item::Image>

=item * L<WWW::MeGa::Item::Other> - represents a item for which no specific object was found

=item * L<WWW::MeGa::Item::Text>

=item * L<WWW::MeGa::Item::Video>

=back


=head1 METHODS

=cut

use Carp qw(confess);
use File::Basename qw(basename dirname);

our $VERSION = '0.09_3';

=head2 new($relative_path, $config, $cache)

creates a new WWW::MeGa::Item::* object based on mime type of the file specified by $relative_path.

$config is a Config::Simple object, containing amongst other things the root-path to build a absolute path.

$cache is a hash reference to cache the exif data

=cut

sub new
{
	my $proto = shift;
	my $self = {};
        $self->{path_rel} = shift; # relative path
	$self->{config} = shift;
	$self->{cache} = shift;

        $self->{path} = File::Spec->catfile($self->{config}->param('root'), $self->{path_rel});	# absolute path to filename
	$self->{file} = basename $self->{path};		# filename
	$self->{folder} = dirname $self->{path};	# folder


        my $type;
        if (-d $self->{path})
        {
                $type = 'Folder';
        } else
        {
                use MIME::Types;
                my $mt = MIME::Types->new();
                my $mime = $mt->mimeTypeOf($self->{path});

                $type = $mime ? ucfirst ((split '/', $mime)[0]) : 'Other';
        }
        my $class = 'WWW::MeGa::Item::' . ucfirst $type;
	# there is no other way to load the module in runtime, so please:
	unless (eval "require $class")	## no critic
        {
                $class = 'WWW::MeGa::Item::Other';
                require WWW::MeGa::Item::Other or confess "$class: $! (@INC)";
        }

	$self->{type} = $type;

	bless $self, $class;
	return $self;
}


=head2 data

returns necessary data for rendering the template

=cut

sub data
{

	my $self = shift;
	my $data =
	{
		FILE => $self->{file},
		PATH => $self->{path},
		PATH_REL => $self->{path_rel},
		NAME => $self->{file},
	};
	$data->{EXIF} = $self->exif;
	$data->{TYPE} = (split(/::/, Scalar::Util::blessed($self)))[-1];
	return $data;
}


=head2 exif

read, return and cache the exif data for the represented file

=cut

sub exif
{
	my $self = shift;
        return unless $self->{config}->param('exif');
	#$self->{cache}->{exif}->{23} = "foo";

	return $self->{cache}->{exif}->{$self->{path}} if ($self->{cache}->{exif}->{$self->{path}});

        use Image::ExifTool;
        my $et = Image::ExifTool->new();
        my %data;
        warn "reading exif from $self->{path}" if $self->{config}->param('debug');
	my $exif = $et->ImageInfo((-d $self->{path}) ? $self->thumbnail_source : $self->{path});
	return if $exif->{Error};
	$self->{cache}->{exif}->{$self->{path}} = $exif;
	return $exif;
}


=head2 thumbnail_sized($size, $type)

makes sure that a thumbnail exists (calls C<$self->thumbnail> in case its not) in requested size and returns a path to it.
Should not be called directly but through the caching methode

=cut

sub thumbnail_sized
{
	use Image::Magick;

	my $self = shift;
	my $size = shift;
	my $type = shift;
	my $img = $self->thumbnail_source or die "no thumbnail source for $self->{path}, type: $self->{type}";
	my $ret;

        my $image = Image::Magick->new;

        $ret = $image->Read($img);
                die $ret if $ret;
	warn "loaded $img" if $self->{config}->param('debug');

        #$ret = $image->Scale($size . 'x' . $size);
	$ret = $image->Resize($size . 'x' . $size);
                die $ret if $ret;
	warn "scaled $img" if $self->{config}->param('debug');

	$ret = $image->AutoOrient();
		die $ret if $ret;
	warn "oriented $img" if $self->{config}->param('debug');

        return $image->ImageToBlob(magick=>$type);
}


=head2 thumbnail_source

returns the source for the thumbnail.
Thats the original file that can be scaled via thumbnail_sized. Think
of it as a image represenation for the file type.
This methode selects a icon based on the mime type. But this methode
gets overwritten for images and videos to have a real thumbnail.

=cut

sub thumbnail_source
{
	my $self = shift;
	return File::Spec->catdir($self->{config}->param('icons'), $self->{type} .'.'. ($self->{config}->param('icons-type') || 'png') );
}


=head2 thumbnail($size)

returns the actual thumbnail

=cut

sub thumbnail
{
	my $self = shift;
	my $size = shift;
	my $type = $self->{config}->param('thumb-type');
	my $cache = $self->{config}->param('cache');
	#my $sized = $self->thumbnail_path($size,$cache) or return undef;
	my $sized = File::Spec->catdir($cache, $self->{path} . '_' . $size . '.' . $type);
	warn "sized: $sized" if $self->{config}->param('debug');

	unless ( -e $sized)
	{
		$self->prepare_dir($sized) or warn "could not create dir for $sized";

		my $data = $self->thumbnail_sized($size,$type);
		return unless $data;

		open my $fh, '>', $sized or warn "could not write thumbnail to $sized"; #FIXME: bin-mode?
		print $fh $data;
		close $fh;
	}
		
	return $sized;
}


=head2 original

returns the original file

=cut

sub original
{
	my $self = shift;
	die "file '$self->{path}' does not exist" unless -f $self->{path};
	return $self->{path};
}

sub prepare_dir
{
	my $self = shift;
	my $file = shift;
	my $folder = dirname $file;
		
	unless ( -d $folder )
	{
		use File::Path;
		unless(mkpath $folder)
		{
			warn "could not create $folder";
			return;
		}
	}
	return $folder;
}
1;
