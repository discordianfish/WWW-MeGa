package WWW::MeGa::Item::Text;
use strict;
use warnings;

=head1 NAME

WWW::MeGa::Item::Text - Representing a text file in L<WWW::MeGa>


=head1 DESCRIPTION

See L<WWW::MeGa::Item>

=head1 CHANGED METHODS

=cut

use base 'WWW::MeGa::Item';

our $VERSION = '0.09_3';


=head1 data

gets the common data from C<$self->SUPER::data>, puts the text file
content in C<$data->{CONTENT}> and return the data.

=cut

sub data
{
	my ($self, @args) = @_;
	my $data = $self->SUPER::data($self,@args);

	open my $fh, '<', $self->original or die $!;
	#my @f = <$fh>;
	$data->{CONTENT} = <$fh>;
	close $fh;
	return $data;
}

1;
