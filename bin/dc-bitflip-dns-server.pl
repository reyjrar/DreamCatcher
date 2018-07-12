#!perl
# PODNAME: dc-bitflip-dns-server.pl
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use JSON::MaybeXS;
use Net::DNS;
use Net::DNS::Nameserver;
use YAML;

my %DEFAULT = (
    port => 53,
    addr => "0.0.0.0",
);
my ($opt,$usage) = describe_options("%c %o",
    ['config=s', "Config file", { required => 1 } ],
    [],
    ['addr=s',  "DNS Listening Address, default $DEFAULT{addr}",
                { default => $DEFAULT{addr} }],
    ['port=i',  "DNS Listening Port, default $DEFAULT{port}",
                { default => $DEFAULT{port} }],
    [],
    ['help', "Display this help and exit", { shortcircuit => 1 }],
);
if( $opt->help ) {
    print $usage->text;
    exit;
}

=head2 CONFIG File Format

The YAML config file looks like this:

    ---
    domains:
      booking.com:
        records:
          A: 1.2.3.4
          MX: 10 mx.example.com
        flipped:
          - bnoking.com
          - bookiog.com

=cut

my $CFG = YAML::LoadFile($opt->config);

my %DomainMap = ();
foreach my $domain ( sort keys %{ $CFG->{domains} } ) {
    foreach my $flipped ( @{ $CFG->{domains}{$domain}{flipped} } ) {
        $DomainMap{$flipped} = $domain;
    }
}

my $MATCH = join( '|', map { quotemeta } sort keys %DomainMap );
my $JSON = JSON->new->canonical->utf8;

sub handle_request {
    my @incoming = @_;
    my @names    = qw(qname qclass qtype peerhost query conn);
    my %q = map { shift(@names) => $_ } @incoming;

    my $log = {
        src_ip => $q{peerhost},
        query  => {
            class => $q{qclass},
            type => $q{qtype},
            name => $q{qname},
        },
    };

    my $rcode = $log->{status} = "NXDOMAIN";
    my (@ans,@auth,@add);

    my $name = lc $q{qname};
    if( my($flipped) = ($name =~ /($MATCH)$/) ) {
        $log->{src_domain} = $flipped;
        if( my $domain = $DomainMap{$flipped} ) {
            $log->{dst_domain} = $domain;
            if( exists $CFG->{domains}{$domain}{records}{$q{qtype}} ) {
                $rcode = $log->{status} = "NOERROR";
                my $answer = $CFG->{domains}{$domain}{records}{$q{qtype}};
                my $faked  = $q{qname} =~ s/$flipped/$domain/ri;
                # Faked Response
                push @ans, Net::DNS::RR->new("$faked $q{qclass} $q{qtype} $answer");
                # Original
                push @add, Net::DNS::RR->new("$q{qname} $q{qclass} $q{qtype} $answer");
            }
        }
    }
    output($log->{status} eq 'NOERROR' ? {color=>"green"} :{stderr=>1,color=>'red'},
        sprintf "QUERY %s [%s] from %s for '%s %s %s': %s",
            $log->{status},
            $log->{src_domain} || 'UNKNOWN',
            $log->{src_ip},
            $log->{query}{class},
            $log->{query}{type},
            $log->{query}{name},
            $JSON->encode($log)
    );

    return ( $rcode, \@ans, \@auth, \@add, { aa => 1 } );
}

my $ns = Net::DNS::Nameserver->new(
    LocalAddr => $opt->addr,
    LocalPort => $opt->port,
    ReplyHandler => \&handle_request,
    Verbose => (CLI::Helpers::def('VERBOSE') || CLI::Helpers::def('DEBUG')) ? 1 : 0,
);
output({color=>'cyan'}, "bitflip dns server started");
$ns->main_loop;
