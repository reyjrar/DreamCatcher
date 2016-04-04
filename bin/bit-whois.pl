#!/usr/bin/env perl
# PODNAME: bit-whois.pl
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Net::Whois::Raw;
use Net::Whois::Parser;
$Net::Whois::Raw::OMIT_MSG   = 1;
$Net::Whois::Raw::CHECK_FAIL = 0;
$Net::Whois::Raw::CACHE_DIR  = "$ENV{HOME}/tmp";
$Net::Whois::Raw::TIMEOUT    = 2;

my $domain = shift @ARGV;
$domain ||= 'google.com';

my @parts = split /\./, lc $domain;

my %VALID = map { $_ => 1 } split '', q{ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-};

my $word = shift @parts;
my %variations = ( $domain => 1 );

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
        $variations{lc join('.', $copy, @parts)}++;
    }
}
debug("Found variations: ");
debug_var([sort keys %variations]);

my @available = ();
foreach my $variation (sort keys %variations) {
    verbose("Trying $variation.");
    my ($raw,$error,$info) = (undef,undef,'');
    do {
        sleep 60 if defined $raw;
        local $@ = undef;
        eval {
            $raw = whois($variation);
            1;
        } or do {
            $error = $@;
            output({stderr=>1,color=>'red'}, "WHOIS ERROR: $error");
        };
    } while ( $raw =~ /LIMIT EXCEEDED/ );

    if( defined $raw && $raw =~ /No match for domain/ ) {
        $error = undef;
        $info  = undef;
    }
    elsif(defined $raw) {
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
            output("# Reference $domain found with $info");
        }
        else {
            output("# Reference $domain NOT FOUND");
        }
    }
    else {
        output({color=>defined $error ? 'red' : defined $info ? 'cyan' : 'green'},
            sprintf "$domain variation $variation is %s\n", defined $info ? "taken ($info)" :
                                                    defined $error  ? '!! ERROR !!' : '** AVAILABLE **'
        );
        push @available, $variation if !defined $info && !defined $error;
    }
}
if( @available ) {
    output({data=>1},"$_") for @available;
    output({color=>'cyan'},
        sprintf "\n # [%s] Available Variations %d of %d, %0.2f%%\n\n",
            $domain, scalar(@available), scalar(keys %variations), 100*(scalar(@available) / scalar(keys %variations))
    );
}
