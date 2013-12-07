#!/usr/bin/env perl
#
use strict;
use warnings;

use Net::Whois::Raw;
use Net::Whois::Parser;
$Net::Whois::Raw::OMIT_MSG   = 1;
$Net::Whois::Raw::CHECK_FAIL = 0;
$Net::Whois::Raw::CACHE_DIR  = "$ENV{HOME}/tmp";
$Net::Whois::Raw::TIMEOUT    = 10;

my $domain = shift @ARGV;
$domain ||= 'google.com';

my @parts = split /\./, lc $domain;

my %VALID = map { $_ => 1 } split '', q{ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-};

my $word = shift @parts;
my @variations = ( $domain );

for my $place ( 0 .. length($word)-1 ) {
    my $letter = substr($word,$place,1);

    my %valid = %VALID;
    delete $valid{'-'} if $place == 0 || $place == length($word)-1;

    my $base = ord($letter);
    for my $os ( 0..7 ) {
        my $xor = 2 ** $os;
        my $new = chr($base ^ $xor);
        next unless exists $valid{$new};
        my $copy = $word;
        substr($copy,$place,1,$new);
        push @variations, join('.', $copy, @parts);
    }
}

my @available = ();
foreach my $variation (@variations) {
    my ($raw,$info) = (undef,'');
    eval {
        $raw = whois($variation);
    };
    my $error = $@;

    if( defined $raw && $raw =~ /No match for domain/ ) {
        $error = undef;
        $info  = undef;
    }
    else {
        eval {
            my $result = parse_whois( raw => $raw, domain => $variation );
            die "parse error" unless defined $result && ref $result eq 'HASH';

            if( exists $result->{nameservers} ) {
                $info = join (',', sort map { exists $_->{domain} ? $_->{domain} : $_->{ip}  } @{ $result->{nameservers} } );
            }
            elsif(exists $result->{emails} ) {
                $info = join( ',', sort @{ $result->{emails} } );
            }
            else {
                foreach my $f (qw(admin_email tech_email billing_email)) {
                    last if length $info;
                    $info = $result->{$f} if exists $result->{$f};
                }
            }
        };
        $error .= "\n$@" if $@;
    }

    if( $domain eq $variation ) {
        # Reference:
        if( defined $info ) {
            print "# Reference $domain found with $info\n";
        }
        else {
            print "# Reference $domain NOT FOUND\n";
        }
    }
    else {

        printf "$domain variation $variation is %s\n", defined $info ? "taken ($info)" :
                                                    defined $error  ? '!! ERROR !!' : '** AVAILABLE **';
        print "(error) $error\n" if defined $error && length $error;
        print map { "   $_\n" } split /[\r\n]+/, $raw if !$info && defined $error && defined $raw && length $raw;
        push @available, $variation if !defined $info && !defined $error;
    }
}
if( @available ) {
    printf "\n # [%s] Available Variations %d of %d, %0.2f%%\n\n", $domain, scalar(@available), scalar(@variations), 100*(scalar(@available) / scalar(@variations));
    print "$_\n" for @available;
}
