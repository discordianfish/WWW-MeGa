package WWW::MeGa::Item::Text;
use WWW::MeGa::Item;
our @ISA = qw(WWW::MeGa::Item);

sub data
{
	my ($self, @args) = @_;
	my $data = $self->SUPER::data($self,@args);

	open FILE, '<', $self->original or die $!;
	my @f = <FILE>;
	$data->{CONTENT} = "@f";
	close FILE;
	return $data;
}
1
