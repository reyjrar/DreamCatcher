#!/usr/bin/env perl
#
use strict;
use warnings;
use feature 'say';

use CLI::Helpers qw(:output);
use DreamCatcher::Feathers;
use FindBin;
use Getopt::Long::Descriptive;
use Path::Tiny;
use Pod::Usage;

#------------------------------------------------------------------------#
# Path Setup
my $path_base    = path("$FindBin::Bin")->parent;
my $path_helpers = $path_base->child('helpers');

#------------------------------------------------------------------------#
# Argument Parsing
my ($opt,$usage) = describe_options(
    "%c %o",
    [],
    [ 'feather|f=s@', "Specify a feather to run, multiple options accepted." ],
    [ 'period|p:i',   "Number of seconds to check, default: 7200", {default=>7200} ],
    [ 'max|m:i',      "Maximum number of records to process default: 5,000", {default=>5_000} ],
    [],
    [ 'config|c:s', "DreamCatcher Config File", {
        default => $path_base->child('dreamcatcher.yml')->realpath->canonpath,
        callbacks => { exists => sub { -f shift } }
    }],
    [ 'help|h',    'print this menu and exit'],
    [ 'manual|m',  'print the manual'],
);
#------------------------------------------------------------------------#
# Display Documentation
pod2usage(-exit=>0,-verbose=>2) if $opt->manual;
say($usage->text) if $opt->help;

#------------------------------------------------------------------------#
# Configure the Feathers
my $CFG = YAML::LoadFile( $opt->config );
my $Plumage = DreamCatcher::Feathers->new(
    Config => $CFG,
    Log    => \&logger,
);

my %A = ();
foreach my $f (@{ $Plumage->chain('analysis') }) {
    # Configure the feather
    $f->check_period($opt->period);
    $f->batch_max($opt->max);

    # Make it accessible
    $A{$f->name} = $f;
}

foreach my $feather (@{ $opt->feather }) {
    if( exists $A{$feather} ) {
        debug("Running $feather.");
        $A{$feather}->analyze();
    }
    else {
        output({color=>'yellow'}, "Unknown analysis feather '$feather'");
    }
}


# Logging Closure
{
    my %colors = (
        debug   => 'white',
        info    => 'cyan',
        notice  => 'cyan',
        warn    => 'yellow',
        warning => 'yellow',
        err     => 'red',
        error   => 'red',
        crit    => 'red',
        emerg   => 'red',
    );
    my %cb = (
        debug => \&debug,
        info  => sub {
            my $opts = ref $_[0] eq 'HASH' ? shift : {};
            $opts->{level} = 2;
            verbose($opts,@_);
        },
        notice => \&verbose,
    );
    sub logger {
        my ($level,@msgs) = @_;

        my %opts = ( color => $colors{$level} );

        exists $cb{$level} ? $cb{$level}->(\%opts,@msgs)
                           : output(\%opts, @msgs);
    }
}

__END__

=head1 SYNOPSIS

analyze.pl

    Run one or more analysis feathers manually.

Options:

    --help              print help
    --manual            print full manual
    --config            Location of the Config file, see: L</CONFIGURATION>


=head1 OPTIONS

=over 8

=item B<config>

Location of the config file

=back

=head1 DESCRIPTION

This script is used to run one or more of the analysis feathers manually from the
command line.

=head1 CONFIGURATION

The DreamCatcher config is stored in L<YAML|http://yam.org> format.  The defaults look like this:

    ---
    time_zone: America/New_York
    db:
      dsn: dbi:Pg:host=localhost;database=dreamcatcher
      user: admin
      pass:

    network:
    nameservers: &GLOBALnameservers
      - 8.8.8.8
      - 8.8.4.4
    clients: &GLOBALclients
      - 192.168.1.0/24

    pcap:
      dev: any
      snaplen: 1518
      timeout: 100
      filter: (tcp or udp) and port 53
      promisc: 0

    sniffer:
      workers: 4

    analysis:
      disabled: 0

    feather:
      conversation:
        disabled: 0

=cut
