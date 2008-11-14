# $Id$
package WWW::MeGa::Item::Video;
use strict;
use warnings;

=head1 NAME

WWW::MeGa::Item::Video - Representing a video in L<WWW::MeGa>

=head1 DESCRIPTION

See L<WWW::MeGa::Item>

=head1 CHANGED METHODS

=cut

use base 'WWW::MeGa::Item';

our $VERSION = '0.09_4';


=head2 thumbnail_source

extracts a frame from the video file and place it in the thumbnail-dir for
creating thumbnails of it. After that it return the path to that file.

=cut

sub thumbnail_source
{
	my $self = shift;
	if ($self->{config}->param('video-thumbs'))
	{
		my $type = $self->{config}->param('thumb-type');
		my $frame = File::Spec->catdir($self->{config}->param('cache'), $self->{path} .'.'. $type);
		warn "trying access $frame" if $self->{config}->param('debug');

		unless (-e $frame)
		{
			$self->prepare_dir($frame) or die "could not create dir for $frame";
			system('/usr/bin/ffmpeg', '-i', $self->{path}, '-f', 'image2', '-ss', 10, '-vframes', 1, $frame);
		}
		return $frame;
	}
	return;
}

1;
