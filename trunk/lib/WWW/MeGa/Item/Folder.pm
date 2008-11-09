package WWW::MeGa::Item::Folder;
use strict;
use warnings;

use base 'WWW::MeGa::Item';

our $VERSION = '0.09_2';

sub thumbnail_source
{
	my $self = shift;
	my $thumb = File::Spec->catdir($self->{path}, $self->{config}->param('album_thumb'));

	return $thumb if -e $thumb;
	warn "$thumb not found, autoselecting" if $self->{config}->param('debug');
	my $first = $self->first or return;
	my $item = WWW::MeGa::Item->new($first,$self->{config},$self->{cache});
	return $item->thumbnail_source;
}

sub list
{
	my $self = shift;
	my $thumb = $self->{config}->param('album_thumb');
	my @dir;
	opendir my $dh, $self->{path};
	while (my $file = readdir $dh)
	{
		next if $file eq '.' or $file eq '..';
		next if $file eq $thumb;
		push @dir, File::Spec->catdir($self->{path_rel},$file);
	}
	closedir $dh;
	return sort @dir
}

sub first
{
	my $self = shift;
	opendir my $dh, $self->{path};
	while(my $file = readdir $dh)
	{
		next if $file eq '.' or $file eq '..';
		close $dh;
		return File::Spec->catdir($self->{path_rel},$file);
	}
	return;
}

=head 3 neighbours(file)

return the next and previous file/folder of the given path

=cut

sub neighbours
{
	my $self = shift;
	my $path = shift;
	my @files = $self->list;
	my $i;
	my %index = map { $_ => $i++ } @files;

	my $idx = $index{$path};

	return $files[$idx-1], $files[$idx+1];
}
1;
