#!perl
# PODNAME: dc-bitflip-dns-server.pl
use strict;
use warnings;

use Net::DNS;
use Net::DNS::Nameserver;
use Sys::Syslog;

my $SquattedDomains = join '|', map { quotemeta } qw(
    bnoking.com
    bookiog.com
);
my $MATCH = qr/($SquattedDomains)/;
my %ANSWER = (
    A => '96.126.104.52',
    MX => '10 mx.db0.us',
);

openlog("bitsquatting", "ndelay", "local0");

sub handle_request {
    my @incoming = @_;
    my @names    = qw(qname qclass qtype peerhost query conn);
    my %q = map { shift(@names) => $_ } @incoming;

    my $message = sprintf "QUERY: %s %s %s from %s\n", @q{qw(qclass qtype qname peerhost)};
    syslog("info", $message);

    my $rcode = "NXDOMAIN";
    my (@ans,@auth,@add);

    my $name = lc $q{qname};
    if( exists $ANSWER{$q{qtype}} && $name =~ /$MATCH/ ) {
        $rcode = "NOERROR";
        push @ans, new Net::DNS::RR("$q{qname} 5 $q{qclass} $q{qtype} $ANSWER{$q{qtype}}");
    }

    return ( $rcode, \@ans, \@auth, \@add, { aa => 1 } );
}

my $ns = Net::DNS::Nameserver->new(
    LocalAddr => '0.0.0.0',
    LocalPort => 53,
    ReplyHandler => \&handle_request,
    Verbose => 0,
);

$ns->main_loop;
