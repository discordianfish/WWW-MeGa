#!/usr/bin/perl -w
use strict;
use File::Basename;
package WWW::MeGa::Item;

our $VERSION = '0.09_1';

sub new
{
	my $proto = shift;
	my $self = {};
        $self->{path_rel} = shift; # relative path
	$self->{config} = shift;
	$self->{cache} = shift;

        $self->{path} = File::Spec->catfile($self->{config}->param('root'), $self->{path_rel});	# absolute path to filename
	$self->{file} = File::Basename::basename $self->{path};		# filename
	$self->{folder} = File::Basename::dirname $self->{path};	# folder


        my $type;
        if (-d $self->{path})
        {
                $type = 'Folder';
        } else
        {
                use MIME::Types;
                my $mt = MIME::Types->new();
                my $mime = $mt->mimeTypeOf($self->{path});

                if ($mime)
                {
                        $type = ucfirst ((split '/', $mime)[0]);
                } else {
                        $type = 'Other';
                }

        }
        my $class = 'WWW::MeGa::Item::' . ucfirst $type;
        unless (eval "require $class")
        {
                $class = 'WWW::MeGa::Item::Other';
                eval "require $class" or die $!;
        }

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

sub exif
{
	my $self = shift;
        return undef unless $self->{config}->param('exif');
	#$self->{cache}->{exif}->{23} = "foo";

	return $self->{cache}->{exif}->{$self->{path}} if ($self->{cache}->{exif}->{$self->{path}});

        use Image::ExifTool;
        my $et = Image::ExifTool->new();
        my %data;
        warn "reading exif from $self->{path}" if $self->{config}->param('debug');
	my $exif = $et->ImageInfo((-d $self->{path}) ? $self->thumbnail_source : $self->{path});
	return undef if $exif->{Error};
	$self->{cache}->{exif}->{$self->{path}} = $exif;
	return $exif;
}

=head2 thumbnail_sized

makes sure that a thumbnail exists in requested size and returns a path to it
should not be called directly but through the caching methode

=cut
sub thumbnail_sized
{
	use Image::Magick;

	my $self = shift;
	my $size = shift;
	my $type = shift;
	my $img = $self->thumbnail_source or die "no thumbnail source for $self->{path}";
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

returns the source for the thumbnail
thats the original file it that could be scaled via thumbnail_sized

=cut
sub thumbnail_source
{
	my $self = shift;
	return File::Spec->catdir($self->{config}->param('icons'), Scalar::Util::blessed($self) .'.'. ($self->{config}->param('icons-type') || 'png') );
	#use Scalar::Util qw(blessed);
	#return undef;
	
	#return $self->{config}->param('icons'), $class
}

=head2 thumbnail

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
		return undef unless $data;

		open FILE, '>' . $sized or warn "could not write thumbnail to $sized";
		print FILE $data;
		close FILE;
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
	my $folder = File::Basename::dirname $file;
		
	unless ( -d $folder )
	{
		use File::Path;
		unless(mkpath $folder)
		{
			warn "could not create $folder";
			return undef;
		}
	}
	return $folder;
}
1
