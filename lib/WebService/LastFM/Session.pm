package WebService::LastFM::Session;

use strict;
use warnings;

use base qw(Class::Accessor);

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw(
	session
	stream_url
));

sub new {
	my ($class, $args) = @_;
	bless $args, $class;
}

1;
