#!perl
#
# This example demonstrates controlling the Last.FM stream
# using WebService::LastFM.
#
# Win32::OLE and iTunes is required to execute this sctipt.
#

use strict;
use Win32::OLE;
use WebService::LastFM;

# set login data
my $username = 'username';
my $password = 'password';

my $ctrl = WebService::LastFM->new(
		username => $username,
		password => $password,
	);
my $stream_info;

eval {
	$stream_info = $ctrl->get_session;
};

die "$@\n" if $@;

# create an iTunes object, then add the stream url to its playlist
my $itunes = my $itunes = Win32::OLE->new("iTunes.Application");
my $stream = $itunes->LibraryPlaylist->AddURL($stream_info->{stream_url});

$stream->play;

print "Command: ";

while (<>) {
	chomp;

	# fetch now playing song
	if ($_ eq 'get') {
		my $current_track = $ctrl->get_nowplaying;
		print $current_track->artist.': '.$current_track->track."\n";
	}

	# change station
	# mode: personal, profile or random
	elsif ($_ =~ /change\s+(.+)/) {
		my $response;
		eval { $response = $ctrl->change_station($1) };
		if ($@) {
			print "$@\n";
		} else {
			print "Response: $response\n";
		}
	}

	# quit
	elsif ($_ eq 'quit') {
		$stream->delete;
		print "quit...\n";
		last;
	}

	# send a command
	# command: skip, love or ban
	else {
		my $response;
		eval { $response = $ctrl->send_command($_) };
		if ($@) {
			print "$@\n";
		} else {
			print "Response: $response\n";
		}
	}

	print "Command: ";
}

exit;
