package WWW::MeGa::Item::Image;
use WWW::MeGa::Item;
our @ISA = qw(WWW::MeGa::Item);

our $VERSION = '0.09_1';

# the image representation of a image is a image ;)

sub thumbnail_source
{
	my $self = shift;
	return $self->{path};
}

1;
