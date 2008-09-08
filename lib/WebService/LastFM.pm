package WebService::LastFM;

use strict;
use warnings;

use Carp        ();
use Digest::MD5 ();
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);

use WebService::LastFM::Session;
use WebService::LastFM::NowPlaying;

our $VERSION = '0.06';

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->_die('Username and password are required')
        unless $args{username} || $args{password};

    $self->{username} = $args{username};
    $self->{password} = $args{password};
    $self->{ua}       = LWP::UserAgent->new( agent => "WebService::LastFM/$VERSION", );

    return $self;
}

sub ua { $_[0]->{ua} }

sub get_session {
    my $self = shift;

    my $url
        = 'http://ws.audioscrobbler.com/radio/handshake.php'
        . '?username='
        . $self->{username}
        . '&version= ' . "1.1.1"
        . '&platform= ' . "linux"
        . '&passwordmd5='
        . Digest::MD5::md5_hex( $self->{password} );

    my $response = $self->_get_response( GET $url);

    $self->_die('Wrong params passed')
        if !( keys %$response ) || $response->{session} eq 'FAILED';

    %$self = ( %$self, %$response );
    return WebService::LastFM::Session->new($response);
}

sub get_nowplaying {
    my $self = shift;
    my $url  = 'http://ws.audioscrobbler.com/radio/np.php' . '?session=' . $self->{session};

    my $response = $self->_get_response( GET $url);
    return WebService::LastFM::NowPlaying->new($response);
}

sub send_command {
    my ( $self, $command ) = @_;
    $self->_die('Command not passed') unless $command;

    my $url = 'http://ws.audioscrobbler.com/radio/control.php' . '?session=' . $self->{session} . '&command=' . $command;

    my $response = $self->_get_response( GET $url);
    return $response->{response};
}

sub change_station {
    my ( $self, $user ) = @_;
    $self->_die('URL not passed') unless $user;

    my $url = 'http://ws.audioscrobbler.com/radio/adjust.php' . '?session=' . $self->{session} . '&url=' . "user/$user/personal";

    my $response = $self->_get_response( GET $url);
    return $response->{response};
}

sub change_tag {
    my ( $self, $tag ) = @_;
    $self->_die('tag not passed') unless $tag;
    $tag =~ s/ /\%20/;

    my $url = 'http://ws.audioscrobbler.com/radio/adjust.php' . '?session=' . $self->{session} . '&url=' . "globaltags/$tag";

    print "$url\n";
    my $response = $self->_get_response( GET $url);
    return $response->{response};
}

sub _get_response {
    my ( $self, $request ) = @_;
    my $content  = $self->_do_request($request);
    my $response = $self->_parse_response($content);
    return $response;
}

sub _parse_response {
    my ( $self, $content ) = @_;
    my $response = {};

    $response->{$1} = $2 while ( $content =~ s/^(.+?) *= *(.*)$//m );

    return $response;
}

sub _do_request {
    my ( $self, $request ) = @_;
    my $response = $self->ua->simple_request($request);

    $self->_die( 'Request failed: ' . $response->message )
        unless $response->is_success;

    return $response->content;
}

sub _die {
    my ( $self, $message ) = @_;
    Carp::croak($message);
}

1;

__END__

=head1 NAME

WebService::LastFM - Simple interface to Last.FM Web service API

=head1 SYNOPSIS

  use WebService::LastFM;

  my $lastfm = WebService::LastFM->new(
      username => $username,
      password => $password,
  );

  # get a sessoin key and stream URL to identify your stream
  my $stream_info = $lastfm->get_session;
  my $session_key = $stream_info->session;
  my $stream_url  = $stream_info->stream_url;

  # get the song information you are now listening
  my $nowplaying = $lastfm->get_nowplaying;

  for (qw(
      price
      shopname
      clickthrulink
      streaming
      discovery
      station
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
      radiomode
      recordtoprofile
  )){
      print $nowplaying->$_;
  }

  # send a command
  $lastfm->send_command($command);

  # change the station
  $lastfm->change_station($friend);

=head1 DESCRIPTION

WebService::LastFM provides you a simple interface to Last.FM Web
service API. It currently supports Last.FM Stream API.

=head1 CAVEAT

WebServices::LastFM is now obsolete and doesn't cover all over the API
which Last.fm offers. If you'd like to take over it from me to work on
implementing, please give me a line, I'll let you have it.

=head1 METHODS

=over 4

=item new(I<%args>)

  $lastfm = WebService::LastFM->new(
      username => $username,
      password => $password,
  );

Creates and returns a new WebService::LastFM object.

=item get_session()

  $stream_info = $lastfm->get_session;

Returns a session key and stream URL as a WebService::LastFM::Session
object.

=item get_nowplaying()

  $current_song = $lastfm->get_nowplaying;

Returns a WebService::LastFM::NowPlaying object to retrieve the
information of the song you're now listening.

=item send_command(I<$command>)

  $response = $lastfm->send_command($command);

Sends a command to Last.FM Stream API to control the
streaming. C<$command> can be one of the follows: I<skip>, I<love>,
I<ban>, I<rtp>, or I<nortp>.

I<$response> which you'll get after issuing a command will be either
'OK' or 'FAILED' as a string.

=item change_station(I<$friend>)

  $response = $lastfm->change_station($friend);

Changes the station of your stream to C<$friend>'s one.

I<$response> which you'll get after issuing a command will be either
'OK' or 'FAILED' as a string.

=item change_tag(I<$tag>)

  $response = $lastfm->change_tag($tag);

Change the station of your stream to play music tagged with C<$tag>.

$response which you'll get after issuing a command will be either
'OK' or 'FAILED' as a string.

=item ua

  $lastfm->ua->timeout(10);

Returns the LWP::UserAgent object which is internally used by
C<$lastfm> object. You can set some values to customize its
behavior. See the documentation of L<LWP::UserAgent> for more details.

=back

=head1 SEE ALSO

=over 4

=item * Last.FM

L<http://www.last.fm/>

=item * Last.FM Stream API documentation

L<http://www.audioscrobbler.com/development/lastfm-ws.php>

=item * L<LWP::UserAgent>

=back

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentarok@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2008 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
