package WebService::LastFM::NowPlaying;

use strict;
use warnings;

use base qw(Class::Accessor);

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw(
	streaming
	station
	station_url
	stationfeed
	stationfeed_url
	artist
	artist_url
	track
	track_url
	album
	album_url
	albumcover_small
	albumcover_medium
	albumcover_large
	trackduration
	trackprogress
	radiomode
	recordtoprofile
));

sub new {
	my ($class, $content) = @_;
	my $self = bless {}, $class;
	$self->_fetch_nowplaying_info($content);
	return $self;
}

sub _fetch_nowplaying_info {
	my ($self, $content) = @_;
	$self->{$1} = $2
		while ($content =~ s/^(.+?)\s*=\s*(.+?)$//m);
	return;
}

1;
