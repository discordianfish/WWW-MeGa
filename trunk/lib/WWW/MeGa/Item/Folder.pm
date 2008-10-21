package WWW::MeGa::Item::Folder;
use WWW::MeGa::Item;
our @ISA = qw(WWW::MeGa::Item);

our $VERSION = '0.09_1';

sub thumbnail_source
{
	my $self = shift;
	my $thumb = File::Spec->catdir($self->{path}, $self->{config}->param('album_thumb'));

	return $thumb if -e $thumb;
	warn "$thumb not found, autoselecting" if $self->{config}->param('debug');
	my $first = $self->first or return undef;
	my $item = WWW::MeGa::Item->new($first,$self->{config},$self->{cache});
	return $item->thumbnail_source;
}

sub list
{
	my $self = shift;
	my $thumb = $self->{config}->param('album_thumb');
	my @dir;
	opendir DIR, $self->{path};
	while (my $file = readdir DIR)
	{
		next if $file eq '.' or $file eq '..';
		next if $file eq $thumb;
		push @dir, File::Spec->catdir($self->{path_rel},$file);
	}
	closedir DIR;
	return sort @dir
}

sub first
{
	my $self = shift;
	opendir DIR, $self->{path};
	while(my $file = readdir DIR)
	{
		next if $file eq '.' or $file eq '..';
		close DIR;
		return File::Spec->catdir($self->{path_rel},$file);
	}
	return undef;
}
1
