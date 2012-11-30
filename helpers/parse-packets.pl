#!/usr/bin/env perl
#
use strict;
use warnings;

use FindBin;
use POE::Filter::Reference;
use YAML;

use lib "$FindBin::Bin/../lib";
use DreamCatcher::Packet;
use DreamCatcher::Feathers;

# Global Object Instances
my $CFG = YAML::LoadFile( $ARGV[0] );
my $FILTER = POE::Filter::Reference->new();
my $FEATHERS = DreamCatcher::Feathers->new( Config => $CFG );
my $raw = undef;

# Handle reading events back and forth
binmode(STDIN);
binmode(STDOUT);
$|=1;           # Autoflush STDOUT for POE::Filter::Reference

while( sysread(STDIN, $raw, 4096) ) {
	my $packets = $FILTER->get([$raw]);

	foreach my $raw_packet (@{ $packets }) {
        my $packet = DreamCatcher::Packet->new( $raw_packet );

        foreach my $feather ( @{ $FEATHERS->chain }) {
            $feather->process( $packet );
        }

        if( $packet->valid ) {
            my $out = $FILTER->put( [ $packet->details ] );
            print STDOUT @$out;
        }
        else {
            print STDERR $packet->error . "\n";
        }
	}
}

exit (0);
