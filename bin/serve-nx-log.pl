#!/usr/bin/env perl
#
# Simple DNS Server simply replies with an NXDOMAIN but logs the
# client IP address and question asked via syslog.
#
use strict;
use warnings;
use Net::DNS;
use Net::DNS::Nameserver;
use Sys::Syslog;


openlog("bitsquatting", "ndelay", "local0");

sub handle_request {
    my @incoming = @_;
    my @names    = qw(qname qclass qtype peerhost query conn);
    my %q = map { shift(@names) => $_ } @incoming;

    my $message = sprintf "QUERY: %s %s %s from %s\n", @q{qw(qclass qtype qname peerhost)};
    syslog("info", $message);

    return ( "NXDOMAIN", [], [], [], { aa => 1 } );
}

my $ns = Net::DNS::Nameserver->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 53,
    ReplyHandler => \&handle_request,
    Verbose => 0,
);

$ns->main_loop;
