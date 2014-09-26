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
use YAML;

# DreamCatcher Libraries
use lib "$FindBin::Bin/../lib";

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use POE qw(
    Component::Pcap
    Component::Log4perl
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
$CFG->{sniffer}{workers} ||= 2;
$CFG->{analysis}{disabled} ||= 0;
# Logging
my $LOG_CONFIG = File::Spec->catfile($BASEDIR, 'logging.conf');
$App::Daemon::l4p_conf = $LOG_CONFIG if -f $LOG_CONFIG;
$App::Daemon::as_user  = 'root';
$App::Daemon::as_group = 'root';

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

my $ORIG = $$;
# Daemonize?
daemonize();

#------------------------------------------------------------------------#
# Sessions
my $log_id = POE::Component::Log4perl->spawn(
    Alias      => 'log',
    Category   => 'default',
    ConfigFile => $LOG_CONFIG,
);
my $pcap_session_id = POE::Component::Pcap->spawn(
    Alias       => 'pcap',
    Device      => $CFG->{pcap}{dev},
    Dispatch    => 'dispatch_packets',
    Session     => 'sniffer',
);

my $sniffer_session_id = POE::Session->create(
    inline_states => {
        _start => \&sniffer_start,
        _stop  => sub { warn "sniffer is stopping ..\n"; },

        # Main functions
        dispatch_packets => \&sniffer_dispatch_packets,
        show_stats       => \&sniffer_show_stats,

        # Analyzer Management
        analyzer_start  => \&analyzer_start,
        analyzer_error  => \&analyzer_error,
        analyzer_stdout => \&analyzer_stdout,
        analyzer_stderr => \&analyzer_stderr,
        analyzer_chld   => \&analyzer_chld,

        # Worker Management
        spawn_worker => \&sniffer_spawn_worker,
        # Worker Handling
        worker_error  => \&worker_error,
        worker_stdout => \&worker_stdout,
        worker_stderr => \&worker_stderr,
        worker_chld   => \&worker_chld,
    },
    heap => {
        respawn => {},
        workers => [],
        _workers => {},
        worker => undef,
    },
);

if( $$ != $ORIG ) {
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
    for ( 1 .. $CFG->{sniffer}{workers} ) {
        $kernel->yield('spawn_worker');
    }
    # Analyzer
    $kernel->yield('analyzer_start') unless $CFG->{analysis}{disabled};

    # Start the Packet Capture
    $kernel->post( pcap => 'run' );

    # Statistics Event
    $kernel->delay( show_stats => 60 );
}
sub sniffer_show_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = exists $heap->{stats} ? delete $heap->{stats} : undef;
    if( defined $stats && ref $stats eq 'HASH' ) {
          $kernel->post(log => info => "Stats: " .  join(", ", map { "$_=$stats->{$_}" } keys %{ $stats }) );
    }
    else {
        $kernel->post(log => info => "Stats: No data.");
    }
    $kernel->delay( show_stats => 60 );
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
        $kernel->post(log => error => "failed: $!, rescheduling");
        $kernel->delay_add( spawn_worker => 5 );
        return;
    }
    $kernel->sig_child($worker->PID => 'worker_chld');

    # Respawn
    $heap->{respawn}->{$worker->PID} = 'spawn_worker';

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
        $kernel->post(log => error => "unable to assign CPU affinity for worker: " . $worker->ID . " $err");
    }
    $kernel->post(log => info => "successfully spawned worker:" . $worker->ID . " (cpus:" . join(',', @cpus) . ")");
}
#------------------------------------------------------------------------#
# Analyzer Process Handlers
sub analyzer_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $program = File::Spec->catfile( $HELPERS, "run-analyze.pl" );
    my $worker = POE::Wheel::Run->new(
        Program      => $^X, # Special variable, current running Perl Version
        ProgramArgs  => [ $program, $config_file ],
        ErrorEvent   => 'analyzer_error',
        StdoutEvent  => 'analyzer_stdout',
        StderrEvent  => 'analyzer_stderr',
        StdioFilter  => POE::Filter::Line->new(),
        StderrFilter => POE::Filter::Line->new(),
    );
    if (! defined $worker) {
        $kernel->post(log => error => "failed: $!, rescheduling");
        $kernel->delay_add( analyzer_start => 5 );
        return;
    }
    $heap->{analyzer} = $worker;
    $kernel->sig_child($worker->PID => 'analyzer_chld');
    $heap->{respawn}->{$worker->PID} = 'analyzer_start';
    $kernel->post(log => info => sprintf 'Successfully started the analysis child[%d], id:%d.', $worker->PID, $worker->ID);
}
sub analyzer_chld {
    my ($kernel,$heap,$pid,$status) = @_[KERNEL,HEAP,ARG1,ARG2];
    $kernel->post(log => error => "Received a SIG_CHLD from analyzer $pid");

    my $respawn = exists $heap->{respawn}{$pid} ? delete $heap->{respawn}{$pid} : undef;
    if(defined $respawn) {
        $kernel->post(log => info => "Calling respawn: $respawn");
        $kernel->yield( $respawn );
    }
}
sub analyzer_error {
    my ($kernel, $op, $code, $wheel_id, $handle) = @_[KERNEL, ARG0, ARG1, ARG3, ARG4];
    $kernel->post(log => warn => "analyzer wheel_id = $wheel_id threw an error: $op code:$code on $handle");
    if ($op eq 'read' and $code == 0 and $handle eq 'STDOUT') {
        $kernel->post(log => error => "analyzer error = $wheel_id closed STDOUT");
    }
}
sub analyzer_stdout {
    my ($kernel,$heap,$details) = @_[KERNEL,HEAP,ARG0];
    $kernel->post(log => info => "ANALYZER: $details");
}
sub analyzer_stderr {
    my ($kernel,$heap,$errmsg) = @_[KERNEL,HEAP,ARG0];
    $kernel->post(log => error => "ANALYZER: $errmsg");
}
#------------------------------------------------------------------------#
# Worker Process Handlers
sub worker_error {
    my ($kernel, $op, $code, $wheel_id, $handle) = @_[KERNEL, ARG0, ARG1, ARG3, ARG4];
    $kernel->post(log => warn => "sniffer wheel_id = $wheel_id threw an error: $op code:$code on $handle");
    if ($op eq 'read' and $code == 0 and $handle eq 'STDOUT') {
        $kernel->post(log => error => "wheel_id = $wheel_id closed STDOUT, respawning another worker");
    }
}
sub worker_chld {
    my ($kernel,$heap,$pid,$status) = @_[KERNEL,HEAP,ARG1,ARG2];
    $kernel->post(log => error => "Received a SIG_CHLD from a worker $pid");

    my $wheel_id = exists $heap->{pid_to_wheel} ? delete $heap->{pid_to_wheel}{$pid} : undef;
    if(defined $wheel_id && exists $heap->{_workers}{$wheel_id}) {
        delete $heap->{_workers}{$wheel_id};
        $heap->{workers} = [ sort { $a <=> $b } keys %{ $heap->{_workers} } ];
        $heap->{worker} = 0;
    }

    my $respawn = exists $heap->{respawn}{$pid} ? delete $heap->{respawn}{$pid} : undef;
    if(defined $respawn) {
        $kernel->post(log => info => "Calling respawn: $respawn");
        $kernel->yield($respawn);
    }
}
sub worker_stdout {
    my ($heap,$details) = @_[HEAP,ARG0];

    no warnings;
    $heap->{stats}{success}++;
    $heap->{stats}{$details->{qa}}++;
}
sub worker_stderr {
    my ($kernel,$heap,$errmsg) = @_[KERNEL,HEAP,ARG0];
    no warnings;
    $kernel->post(log => error => $errmsg);
    $heap->{stats}{error}++;
}
