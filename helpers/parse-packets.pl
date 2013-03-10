#!/usr/bin/env perl
#
use strict;
use warnings;

use FindBin;
use POE qw(
    Filter::Reference
    Wheel::ReadWrite
    Component::Log4perl
);
use YAML;

use lib "$FindBin::Bin/../lib";
use DreamCatcher::Packet;
use DreamCatcher::Feathers;

# Global Object Instances
my $CFG      = YAML::LoadFile( $ARGV[0] );
my $FEATHERS = DreamCatcher::Feathers->new(
    Config => $CFG,
    Log    => sub { $poe_kernel->post( log => @_ ); },
);

# POE Sessions
my $log_id = POE::Component::Log4perl->spawn(
    Alias      => 'log',
    Category   => 'Parser',
    ConfigFile => "$FindBin::Bin/../logging.conf",
);
my $session_id = POE::Session->create(inline_states => {
    _start => \&start_session,
    _stop  => sub { },
    input  => \&handle_input,
    error  => \&handle_error,
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
        InputEvent   => 'input',
        ErrorEvent   => 'error',
    );
    $kernel->post(log => 'info' => "startup successful");
}

sub handle_input {
    my ($kernel,$heap,$raw_packet) = @_[KERNEL,HEAP,ARG0];

    my $packet = DreamCatcher::Packet->new( Raw => $raw_packet );

    if( $packet->valid ) {
        foreach my $feather ( @{ $FEATHERS->chain }) {
            $feather->process( $packet );
        }
        my $dt = $packet->details;
        my ($q) = $packet->dns->question;
        my $ques = join(' ', $q->qclass, $q->qtype, $q->qname);
        $kernel->post( log => info => "$dt->{qa} $dt->{client} ($dt->{client_id}) to $dt->{server} ($dt->{server_id}) : $ques");
        $heap->{wheel}->put( $dt );
    }
    else {
        $kernel->post( log => error => $packet->error );
        print STDERR $packet->error . "\n";
    }
}

sub handle_error {
    my ($operation, $errnum, $errstr, $id) = @_[ARG0..ARG3];
    if ($operation eq "read" and $errnum == 0) {
        $poe_kernel->post(log => fatal => "Received EOF, shutting down $id");
        $poe_kernel->shutdown();
    }
    else {
        $poe_kernel->post(log => warn => "Wheel $id encountered $operation error $errnum: $errstr\n");
    }
}
