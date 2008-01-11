use strict;
use warnings;
use Test::More;
use WebService::LastFM;

my $username = $ENV{WEBSERVICE_LASTFM_TEST_USERNAME};
my $password = $ENV{WEBSERVICE_LASTFM_TEST_PASSWORD};

if ($username && $password) {
    plan tests => 6;
}
else {
    plan skip_all => "Set ENV:WEBSERVICE_LASTFM_TEST_USERNAME/PASSWORD";
}

my $lastfm;
isa_ok(($lastfm = WebService::LastFM->new(
    username => $username,
    password => $password,
)), 'WebService::LastFM');

my $stream_info;
isa_ok(($stream_info = $lastfm->get_session()), 'WebService::LastFM::Session');
like($stream_info->session, qr/[a-z0-9]{32}/);
like($stream_info->stream_url, qr/^http:/);

my $now_playing;
isa_ok(($now_playing = $lastfm->get_nowplaying()), 'WebService::LastFM::NowPlaying');
ok($now_playing->streaming);
