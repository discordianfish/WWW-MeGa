package CGI::Application::Phosy::Item::Video;
use CGI::Application::Phosy::Item;
our @ISA = qw(CGI::Application::Phosy::Item);

sub thumbnail_source
{
	my $self = shift;
	warn "??";
	if ($self->{config}->param('video-thumbs'))
	{
		my $type = $self->{config}->param('thumb-type');
		my $frame = File::Spec->catdir($self->{config}->param('cache'), $self->{path} .'.'. $type);
		warn "trying access $frame";

		unless (-e $frame)
		{
			$self->prepare_dir($frame) or die "could not create dir for $frame";
			system('/usr/bin/ffmpeg', '-i', $self->{path}, '-f', 'image2', '-ss', 10, '-vframes', 1, $frame);
		}
		return $frame;
	}
	return undef;
}
