#!/usr/bin/env perl
#
$|=1;           # Autoflush STDOUT for POE::Filter::Reference
use strict;
use warnings;

use FindBin;
use POE::Filter::Reference;
use YAML;

use lib "$FindBin::Bin/../lib";
use DreamCatcher::Packet;
use DreamCatcher::Feathers;

my $CFG = YAML::LoadFile( $ARGV[0] );
my $FILTER = POE::Filter::Reference->new();

# Handle reading events back and forth
my $raw = undef;
binmode(STDIN);
binmode(STDOUT);

while( sysread(STDIN, $raw, 4096) ) {
	my $packets = $FILTER->get([$raw]);

	foreach my $raw_packet (@{ $packets }) {
        my $packet = DreamCatcher::Packet->new( $raw_packet );

        if( $packet->valid ) {
            my $out = $FILTER->put( [ $packet ] );
            print STDOUT @$out;
        }
        else {
            print STDERR $packet->error . "\n";
        }
	}
}

exit (0);
