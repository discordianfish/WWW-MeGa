package WWW::MeGa::Item::Image;
use strict;
use warnings;

use base 'WWW::MeGa::Item';

our $VERSION = '0.09_2';

# the image representation of a image is a image ;)

sub thumbnail_source
{
	my $self = shift;
	return $self->{path};
}

1;
