package WWW::MeGa::Item::Text;
use strict;
use warnings;

use base 'WWW::MeGa::Item';

our $VERSION = '0.09_2';

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
