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

my $i = 0;
my %REFERENCE = map { $i++; $_=>$i, $i=>$_ } 'a' .. 'z';

my $domain = shift @ARGV;
$domain ||= 'google.com';

my @parts = split /\./, lc $domain;

my $word = shift @parts;
my @variations = ( $domain );

for my $place ( 0 .. length($word)-1 ) {
    my $letter = substr($word,$place,1);

    my $index = $REFERENCE{$letter};

    foreach my $move (1,-1) {
        my $new = $move + $index;
        if( exists $REFERENCE{$new} ) {
            my $copy = $word;
            substr($copy,$place,1,$REFERENCE{$new});
            push @variations, join('.', $copy, @parts);
        }
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
    print "\n # Available Variations on $domain\n\n";
    print "$_\n" for @available;
}
