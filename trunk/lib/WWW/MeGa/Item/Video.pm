package WWW::MeGa::Item::Video;
use WWW::MeGa::Item;
our @ISA = qw(WWW::MeGa::Item);

our $VERSION = '0.09_1';

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
	return undef;
}
