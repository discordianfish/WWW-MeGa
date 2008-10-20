package WWW::MeGa::Item::Image;
use WWW::MeGa::Item;

our @ISA = qw(WWW::MeGa::Item);

# the image representation of a image is a image ;)

sub thumbnail_source
{
	my $self = shift;
	return $self->{path};
}

1;
