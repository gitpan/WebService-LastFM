package WebService::LastFM;

use strict;
use warnings;

use Carp ();
use Digest::MD5 ();
use LWP::UserAgent;

use WebService::LastFM::NowPlaying;

our $VERSION = '0.01';

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;

	$self->_die('username and password are required.')
		unless $args{username} || $args{password};

	$self->{username} = $args{username};
	$self->{password} = $args{password};
	$self->{ua} = LWP::UserAgent->new(
		agent   => "WebService::LastFM/$VERSION",
	);

	return $self;
}

sub ua { $_[0]->{ua} }

sub get_session {
	my ($self, $mode) = @_;

	my $url = 'http://wsdev.audioscrobbler.com/radio/getsession.php'
	          .'?username='   .$self->{username}
	          .'&passwordmd5='.Digest::MD5::md5_hex($self->{password});

	$url .= '&mode='    .$mode
	        .'&subject='.$self->{username} if $mode;

	my %stream_info;
	my $content = $self->_get_content($url);

	while ($content =~ s/^(.+?)\s*=\s*(.+?)$//m) {
		$stream_info{$1} = $2;
		$self->{$1} = $2;
	}

	$self->_die('wrong params passed')
		if !(keys %stream_info) || $stream_info{session} eq 'FAILED';

	return \%stream_info;
}

sub get_nowplaying {
	my $self = shift;
	my $url = 'http://wsdev.audioscrobbler.com/radio/np.php'
	          .'?session='.$self->{session};
	my $content = $self->_get_content($url);

	return WebService::LastFM::NowPlaying->new($content);
}

sub send_command {
	my ($self, $command) = @_;
	$self->_die('no command passed.') unless $command;

	my $url = 'http://wsdev.audioscrobbler.com/radio/control.php'
	          .'?session='.$self->{session}
	          .'&command='.$command;

	my $content = $self->_get_content($url);
	my ($response) = $content =~ /^response=(.+)$/;

	return $response;
}

sub change_station {
	my ($self, $mode) = @_;
	$self->_die('no mode passed.') unless $mode;

	my $url = 'http://wsdev.audioscrobbler.com/radio/tune.php'
	          .'?session='.$self->{session}
	          .'&mode='   .$mode
	          .'&subject='.$self->{username};

	my $content = $self->_get_content($url);
	my ($response) = $content =~ /^response=(.+)$/;

	return $response;
}

sub _get_content {
	my ($self, $url) = @_;
	my $response = $self->ua->get($url);

	$self->_die('Request faild: '.$response->message)
		unless $response->is_success;

	my $content = $response->content;
	return $content;
}

sub _die {
	my ($self, $message) = @_;
	Carp::croak($message);
}

1;

__END__

=head1 NAME

WebService::LastFM - Simple interfece to Last.FM webservice API

=head1 SYNOPSIS

  use WebService::LastFM;

  my $lastfm = WebService::LastFM->new(
      username => $username,
      password => $password,
  );

  # get a sessoin key and stream URL to identify your stream
  my $stream_info = $lastfm->get_session($mode);

  my $session_key = $stream_info->{session};
  my $stream_url  = $stream_info->{stream_url};

  # get the song information you are now listening
  my $nowplaying = $lastfm->get_nowplaying;

  my $streaming         = $nowplaying->streaming;
  my $station           = $nowplaying->station;
  my $station_url       = $nowplaying->station_url;
  my $stationfeed       = $nowplaying->stationfeed;
  my $stationfeed_url   = $nowplaying->stationfeed_url;
  my $artist            = $nowplaying->artist;
  my $artist_url        = $nowplaying->artist_url;
  my $track             = $nowplaying->track;
  my $track_url         = $nowplaying->track_url;
  my $album             = $nowplaying->album;
  my $album_url         = $nowplaying->album_url;
  my $albumcover_small  = $nowplaying->albumcover_small;
  my $albumcover_medium = $nowplaying->albumcover_medium;
  my $albumcover_large  = $nowplaying->albumcover_large;
  my $trackduration     = $nowplaying->trackduration;
  my $trackprogress     = $nowplaying->trackprogress;
  my $radiomode         = $nowplaying->radiomode;
  my $recordtoprofile   = $nowplaying->recordtoprofile;

  # send a command 
  $lastfm->send_command($command);

  # change the station
  $lastfm->change_station($new_mode);

=head1 DESCRIPTION

WebService::LastFM provides you a simple interface to Last.FM webservice API. It currently supports Last.FM Stream API. See L<http://www.audioscrobbler.com/development/lastfm-ws.php> for details.

=head1 METHODS

=over 4

=item new

  $lastfm = WebService::LastFM->new(
      username => $username,
      password => $password,
  );

Creates and returns a new WebService::LastFM object.

=item get_session

  $stream_info = $lastfm->get_session([$mode]);

Get a session key and stream URL as hashref. Setting I<$mode> parameter allows you to start the stream on a particular station. (The default is your own profile radio station)

=item get_nowplaying

  $current_song = $lastfm->get_nowplaying;

Returns a WebService::LastFM::NowPlaying object to retrieve the currently playing song's information.

=item send_command

  $response = $lastfm->send_command($command);

Sends a command to Last.FM Stream API to control currently playing song. The command can be one of 'I<skip>', 'I<love>' or 'I<ban>'.

I<$response> you get after issuing a command will be whether 'OK' or 'FAILED'.

=item change_station

  $response = $lastfm->change_station($new_mode);

Changes the station of your stream. I<$new_mode> can be one of 'I<personal>', 'I<profile>' or 'I<random>'. Making a donation to Last.FM is required to change the mode to 'personal'. See L<http://www.last.fm/tutorial.php> for more details.

I<$response> you get after changing station will be whether 'OK' or 'FAILED'.

=item ua

  $lastfm->ua->timeout(10);

Returns a LWP::UserAgent object. You can set some values to change its propaties. See the documentation of L<LWP::UserAgent> for more details.

=back

=head1 CAVEAT

WebService::LastFM is in beta version. Besides, Last.FM webservice API's spec haven't fixed yet, so the interface it provides may be changed later.

=head1 SEE ALSO

=over 4

=item * Last.FM

L<http://www.last.fm/>

=item * Last.FM Stream API's documentation

L<http://www.audioscrobbler.com/development/lastfm-ws.php>

=item * L<LWP::UserAgent>

=back

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentarok@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
