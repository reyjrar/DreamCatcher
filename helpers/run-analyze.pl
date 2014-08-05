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
    schedule => \&set_schedule,
    analyze => \&run_analyze,
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
    $kernel->yield( 'schedule' );
    $kernel->post(log => 'info' => "startup successful");
}

sub handle_input {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
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

sub set_schedule {
    my ($kernel,$heap) = $_[KERNEL,HEAP];

    # Retrieve the schedule
    $heap->{schedule} = $FEATHERS->schedule();

    foreach my $name (keys %{ $heap->{schedule} }) {
        $kernel->delay_add( analyze => $heap->{schedule}{$name}, $name );
    }
}

sub run_analyze {
    my ($kernel,$heap,$name) = @_[KERNEL,HEAP,ARG0];

    my $F = $FEATHERS->hash;

    if( !exists $F->{$name} ) {
        $kernel->post(log => error => "run_analyze($name): unknown analyzer");
        return;
    }

    $kernel->post(log => info => "running analyzer $name");
    $F->{$name}->analyze();
    $kernel->delay_add( analyze => $F->{$name}->interval, $name);
    $kernel->post(log => debug => "rescheduled analyzer $name");
}
