#!/usr/bin/env perl
# PODNAME: dreamcatcher.pl
#
# Sniffer based on the Feathers
# Also Includes the Analysis pieces
#
use strict;
use warnings;

use App::Daemon qw(daemonize);
use DateTime;
use File::Basename;
use File::Spec;
use FindBin;
use Log::Log4perl qw(:easy);
use YAML;

# DreamCatcher Libraries
use lib "$FindBin::Bin/../lib";

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE qw(
    Component::Pcap
    Filter::Line
    Filter::Reference
    Wheel::Run
);

#------------------------------------------------------------------------#
# Argument Parsing
my %OPT;
foreach my $opt (qw(-c)) {
    my $v = App::Daemon::find_option( $opt, 1 );
    my $k = substr( $opt, 1 );
    $OPT{$k} = $v if defined $v;
}

#------------------------------------------------------------------------#
# Path Setup
my @BasePath = File::Spec->splitdir("$FindBin::Bin");
pop @BasePath;  # Strip Binary Directory
my $BASEDIR = File::Spec->rel2abs( File::Spec->catdir(@BasePath) );
my $HELPERS = File::Spec->catdir( $BASEDIR, 'helpers' );

#--------------------------------------------------------------------------#
# App Config
my $DEFAULT_CONFIG = File::Spec->catfile($BASEDIR, 'dreamcatcher.yml');
my $config_file = exists $OPT{c} && -f $OPT{c} ? $OPT{c} : $DEFAULT_CONFIG;
my $CFG = YAML::LoadFile( $config_file );
$CFG->{sniffer}{workers} ||= 8;

# Default PCAP Opts
my %pcapOpts = ( dev => 'any', snaplen => 1518, filter => '(tcp or udp) and port 53', promisc => 1 );
if( exists $CFG->{pcap} ) {
    while( my ($k,$v) = each %pcapOpts ) {
        $CFG->{pcap}{$k} = $v unless exists $CFG->{pcap}{$k};
    }
}
else {
    $CFG->{pcap} = \%pcapOpts;
}

# Daemonize?
daemonize();

#------------------------------------------------------------------------#
# Sessions
my $pcap_session_id = POE::Component::Pcap->spawn(
    Alias       => 'pcap',
    Device      => $CFG->{pcap}{dev},
    Dispatch    => 'dispatch_packets',
    Session     => 'sniffer',
);

my $sniffer_session_id = POE::Session->create(inline_states => {
    _start => \&sniffer_start,
    _stop  => sub { warn "sniffer is stopping ..\n"; },
    _child => \&sniffer_handle_sigchld,

    dispatch_packets => \&sniffer_dispatch_packets,
    show_stats       => \&sniffer_show_stats,

    # Worker Management
    spawn_worker  => \&sniffer_spawn_worker,
    kill_worker   => \&sniffer_kill_worker,

    # Worker Handling
    worker_error  => \&worker_error,
    worker_stdout => \&worker_stdout,
    worker_stderr => \&worker_stderr,
});

if( $App::Daemon::background ) {
    $poe_kernel->has_forked();
}

POE::Kernel->run();
exit 0;
#------------------------------------------------------------------------#
sub sniffer_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Set alias
    $kernel->alias_set('sniffer');

    # Configure the Pcap Handler
    $kernel->post( pcap => open_live => @{$CFG->{pcap}}{qw(dev snaplen promisc timeout)} );
    $kernel->post( pcap => set_filter => $CFG->{pcap}{filter} );

    # Create Workers
    $heap->{_workers} = {};
    $heap->{workers} = 0;
    for ( 1 .. 5 ) {
        $kernel->yield('spawn_worker');
    }

    # Start the Packet Capture
    $kernel->post( pcap => 'run' );

    # Statistics Event
    $kernel->delay( show_stats => 5 );
}
sub sniffer_show_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = exists $heap->{stats} ? delete $heap->{stats} : undef;
    if( defined $stats && ref $stats eq 'HASH' ) {
        INFO("Stats breakdown: " .  join(", ", map { "$_=$stats->{$_}" } keys %{ $stats }) );
    }
    else {
        INFO("No packets sniffed.");
    }
    $kernel->delay( show_stats => 5);
}
sub sniffer_dispatch_packets {
    my ($kernel,$heap,$packets) = @_[KERNEL,HEAP,ARG0];

    foreach my $packet ( @{ $packets } ) {
        # Reset worker back to 0
        $heap->{worker} = 0 if $heap->{worker} >= scalar @{ $heap->{workers} };
        $heap->{stats}{total}++;

        # Dispatch to the child
        my $wheel_id = $heap->{workers}[$heap->{worker}];
        $heap->{worker}++;
        $heap->{_workers}{$wheel_id}->put( $packet );
    }
}
sub sniffer_spawn_worker {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $program = File::Spec->catfile( $HELPERS, "parse-packets.pl" );
    my $worker = POE::Wheel::Run->new(
        Program      => $^X, # Special variable, current running Perl Version
        ProgramArgs  => [ $program, $config_file ],
        ErrorEvent   => 'worker_error',
        StdoutEvent  => 'worker_stdout',
        StderrEvent  => 'worker_stderr',
        StdioFilter  => POE::Filter::Reference->new(),
        StderrFilter => POE::Filter::Line->new(),
    );
    if (! defined $worker) {
        ERROR("proc_spawn_worker failed: $!, rescheduling");
        $kernel->delay_add( spawn_worker => 5 );
        return;
    }
    # Track Processors
    $heap->{_workers}{$worker->ID} = $worker;
    $heap->{workers} = [ sort { $a <=> $b } keys %{ $heap->{_workers} } ];
    $heap->{worker} = 0;

    my @cpus = ();
    eval {
        require Sys::CpuAffinity;
        $heap->{_cpus} ||= Sys::CpuAffinity::getNumCpus();
        die "not enough cpu's to tune affinity" if $heap->{_cpus} < 8;
        my $cpus = $heap->{_cpus} > $CFG->{sniffer}{workers} ? 2 : 1;
        for (1 .. $cpus ) {
            my $cpu = int(rand($heap->{_cpus})) + 1;
            push @cpus, $cpu > $heap->{_cpus} ? $heap->{_cpus} : $cpu;
        }
        Sys::CpuAffinity::setAffinity($worker->PID, \@cpus);
    };
    if( my $err = $@ ) {
        ERROR("proc_spawn_worker unable to assign CPU affinity for worker: " . $worker->ID);
    }
    INFO("proc_spawn_worker successfully spawned worker:" . $worker->ID . " (cpus:" . join(',', @cpus) . ")");
}
sub sniffer_kill_worker {
    my ($kernel,$heap,$wheel_id) = @_[KERNEL,HEAP,ARG0];
    $heap->{_workers}{$wheel_id}->kill();
    delete $heap->{_workers}{$wheel_id};

    $heap->{workers} = [ sort { $a <=> $b } keys %{ $heap->{_workers} } ];
    $heap->{worker} = 0;
    INFO("reaped a worker:$wheel_id");
}
sub sniffer_handle_sigchld {
    my ($kernel,$heap,$child,$exit_code) = @_[KERNEL,HEAP,ARG1,ARG2];
    my $child_pid = $child->ID;
    $exit_code ||= 0;
    my $exit_status = $exit_code >>8;
    return unless $exit_code != 0;
    ERROR("Received SIGCHLD from $child_pid ($exit_status)");
}
#------------------------------------------------------------------------#
# Worker Process Handlers
sub worker_error {
    my ($kernel, $op, $code, $wheel_id, $handle) = @_[KERNEL, ARG0, ARG1, ARG3, ARG4];
    if ($op eq 'read' and $code == 0 and $handle eq 'STDOUT') {
        WARN("worker_error: wheel_id = $wheel_id closed STDOUT, respawning another worker");
        $kernel->yield( kill_worker => $wheel_id );
        $kernel->yield( 'spawn_worker' );
    }
}
sub worker_stdout {
    my ($heap,$details) = @_[HEAP,ARG0];

    no warnings;
    $heap->{stats}{success}++;
    $heap->{stats}{$details->{qa}}++;
}
sub worker_stderr {
    my ($heap,$errmsg) = @_[HEAP,ARG0];
    no warnings;
    DEBUG("Packet processing error: $errmsg");
    $heap->{stats}{error}++;
}
