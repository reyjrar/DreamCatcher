#!perl
# PODNAME: dc-component-parse.pl
use strict;
use warnings;

use FindBin;
use Path::Tiny qw(path);
use YAML ();

use DreamCatcher::Packet;
use DreamCatcher::Feathers;

use POE qw(
    Filter::Reference
    Wheel::ReadWrite
    Component::Log4perl
);

# Global Object Instances
my $config_file = $ARGV[0];
my $path_base = path($config_file)->parent;
my $CFG      = YAML::LoadFile( $config_file );
my $FEATHERS = DreamCatcher::Feathers->new(
    Config => $CFG,
    Log    => sub { $poe_kernel->post( log => @_ ); },
);

# POE Sessions
my $log_id = POE::Component::Log4perl->spawn(
    Alias      => 'log',
    Category   => 'Parser',
    ConfigFile => $path_base->child('logging.conf')->realpath->canonpath,
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
    my $id = path($0)->basename;
    $kernel->post(log => 'info' => "$id startup successful");
}

sub handle_input {
    my ($kernel,$heap,$raw_packet) = @_[KERNEL,HEAP,ARG0];

    my $packet = DreamCatcher::Packet->new( Raw => $raw_packet );

    if( $packet->valid ) {
        $FEATHERS->process( $packet );

        my $dt = $packet->details;
        my ($q) = $packet->dns->question;
        my $ques = join(' ', $q->qclass, $q->qtype, $q->qname);
        $kernel->post( log => debug => "$dt->{qa} $dt->{client} ($dt->{client_id}) to $dt->{server} ($dt->{server_id}) : $ques");
        $heap->{wheel}->put( $dt );
    }
    else {
        $kernel->post( log => error => $packet->error );
        print STDERR $packet->error . "\n";
    }
}

sub handle_error {
    my ($operation, $errnum, $errstr, $id, $handle) = @_[ARG0..ARG4];
    $poe_kernel->post(log => warn => "Sniffer Wheel $id ($handle) encountered $operation error $errnum: $errstr\n");

    if ($operation eq "read" and $errnum == 0) {
        $poe_kernel->post(log => fatal => "Sniffer received EOF, shutting down.");
        $poe_kernel->shutdown();
    }
}
