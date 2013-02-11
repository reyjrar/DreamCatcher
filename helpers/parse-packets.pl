#!/usr/bin/env perl
#
use strict;
use warnings;

use FindBin;
use POE qw(
    Filter::Reference
    Wheel::ReadWrite
);
use YAML;

use lib "$FindBin::Bin/../lib";
use DreamCatcher::Packet;
use DreamCatcher::Feathers;


# Global Object Instances
my $CFG      = YAML::LoadFile( $ARGV[0] );
my $FEATHERS = DreamCatcher::Feathers->new( Config => $CFG );

my $session_id = POE::Session->create(inline_states => {
    _start      => \&start_session,
    _stop       => sub { },
    input       => \&handle_input,
});

POE::Kernel->run();
exit(0);

sub start_session {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # IO :)
    $heap->{wheel} = POE::Wheel::ReadWrite->new(
        InputHandle  => \*STDIN,
        OutputHandle => \*STDOUT,
        Filter       => POE::Filter::Reference->new(),
    );
}

sub handle_input {
    my ($kernel,$heap,$packets) = @_[KERNEL,HEAP,ARG0];

	foreach my $raw_packet (@{ $packets }) {
        my $packet = DreamCatcher::Packet->new( $raw_packet );

        foreach my $feather ( @{ $FEATHERS->chain }) {
            $feather->process( $packet );
        }

        if( $packet->valid ) {
            $heap->{wheel}->put( $packet->details );
        }
        else {
            print STDERR $packet->error . "\n";
        }
	}
}
