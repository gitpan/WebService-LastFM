package WebService::LastFM::NowPlaying;

use strict;
use warnings;

use base qw(Class::Accessor);

our $VERSION = '0.02';

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
	my ($class, $args) = @_;
	bless $args, $class;
}

1;
