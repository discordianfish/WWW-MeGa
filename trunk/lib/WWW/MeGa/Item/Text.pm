package WWW::MeGa::Item::Text;
use WWW::MeGa::Item;
our @ISA = qw(WWW::MeGa::Item);

sub data
{
	my ($self, @args) = @_;
	my $data = $self->SUPER::data($self,@args);

	$data->{CONTENT} = $self->original;
	return $data;
}
1
