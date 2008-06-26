package CGI::Application::Phosy::Item::Text;
use CGI::Application::Phosy::Item;
our @ISA = qw(CGI::Application::Phosy::Item);

sub data
{
	my ($self, @args) = @_;
	my $data = $self->SUPER::data($self,@args);

	$data->{CONTENT} = $self->original;
	return $data;
}
1
