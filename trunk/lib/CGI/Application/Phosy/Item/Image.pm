package CGI::Application::Phosy::Item::Image;
use CGI::Application::Phosy::Item;

our @ISA = qw(CGI::Application::Phosy::Item);

# the image representation of a image is a image ;)

sub thumbnail_source
{
	my $self = shift;
	return $self->{path};
}

1;
