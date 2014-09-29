#!/usr/bin/env perl
#
use strict;
use warnings;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(
    Filter::Line
    Wheel::ReadWrite
    Component::Log4perl
);

use FindBin;
use File::Basename;
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
    _start   => \&start_session,
    _stop    => sub { $poe_kernel->shutdown; },
    input    => \&handle_input,
    error    => \&handle_error,
    schedule => \&set_schedule,
    analyze  => \&run_analyze,
});

POE::Kernel->run();
exit(0);

sub start_session {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # So we know when the parent dies
    $heap->{wheel} = POE::Wheel::ReadWrite->new(
        InputHandle  => \*STDIN,
        OutputHandle => \*STDOUT,
        Filter       => POE::Filter::Line->new(),
        InputEvent   => 'input',
        ErrorEvent   => 'error',
    );
    $kernel->yield('schedule');
    my $id = basename($0);
    $kernel->post(log => 'info' => "$id startup successful");
}

sub handle_input {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
    $kernel->post(log => info => "Received input from parent: $msg");
}

sub handle_error {
    my ($operation, $errnum, $errstr, $id, $handle) = @_[ARG0..ARG4];
    $poe_kernel->post(log => warn => "Wheel $id $handle encountered $operation error $errnum: $errstr\n");
    if ($operation eq "read" && $errnum == 0) {
        $poe_kernel->post(log => fatal => "Analysis Wheel $id received EOF, shutting down.");
        $poe_kernel->shutdown();
    }
}
sub set_schedule {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Retrieve the schedule
    $heap->{schedule} = $FEATHERS->schedule();

    foreach my $name (keys %{ $heap->{schedule} }) {
        # First run will be in the first minute
        my $start = int rand(60);
        $kernel->post(log => info => "Schedule set for $name is every $heap->{schedule}{$name} : First run in $start seconds.");
        $kernel->delay_add( analyze => $start, $name );
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
    eval { $F->{$name}->analyze() };
    $kernel->delay_add( analyze => $F->{$name}->interval, $name);
    $kernel->post(log => debug => "rescheduled analyzer $name");
}
