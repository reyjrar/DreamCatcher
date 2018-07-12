#!perl
# PODNAME: dc-bit-whois.pl
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use Net::Whois::Raw;
use Net::Whois::Parser;
$Net::Whois::Raw::OMIT_MSG   = 1;
$Net::Whois::Raw::CHECK_FAIL = 0;
$Net::Whois::Raw::CACHE_DIR  = "$ENV{HOME}/tmp";
$Net::Whois::Raw::TIMEOUT    = 2;

my ($opt,$usage) = describe_options("%c %o domain",
    ["This utility will find all bitflipped variations on a domain and check their availability."],
    [],
    ['help', "Display this help.", {shortcircuit => 1}]
);
if( $opt->help || !@ARGV ) {
    print $usage->text;
    exit;
}

my $domain = shift @ARGV;
my @parts = split /\./, lc $domain;
my %VALID = map { $_ => 1 } split '', q{ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-};

my $word = shift @parts;
my %variations = map { $_ => 1 } ( lc $domain );

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
        my $variation = lc join('.', $copy, @parts);
        verbose({color=>'yellow'}, "New bit variation on $domain: $variation")
            unless exists $variations{$variation};
        $variations{$variation} = 1;
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

    if( defined $raw && $raw =~ /No match for domain/  || $raw =~ /NOT FOUND/ ) {
        $error = undef;
        $info  = undef;
    }
    elsif( defined $raw && $raw =~ /WHOIS LIMIT EXCEEDED/ ) {
        undef($info);
        $error = $raw;
    }
    else {
        eval {
            my $result = parse_whois( raw => $raw, domain => $variation );
            die "parse error" unless defined $result && ref $result eq 'HASH';

            if( $result->{nameservers} && grep { defined } @{ $result->{nameservers} } ) {
                $info = join (',', sort map { exists $_->{domain} ? $_->{domain} : $_->{ip}  } @{ $result->{nameservers} } );
            }
            elsif( $result->{emails} && grep { defined } @{ $result->{emails} } ) {
                $info = join( ',', sort grep { defined } @{ $result->{emails} } );
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
        output({color=>'cyan',sticky=>1}, defined $info ?
            "Reference $domain found with $info" : "Reference $domain not found."
        );
    }
    else {
        verbose({color=>defined $error ? 'red' : defined $info ? 'yellow' : 'green'},
            sprintf "%s variation %s is %s",
                $domain,
                $variation,
                defined $info ? "taken ($info)" : defined $error  ? '!! ERROR !!' : '** AVAILABLE **',
        );
        output({stderr=>1,color=>'red'}, sprintf "(error) %s - %s", $variation, $error) if defined $error && length $error;
        push @available, $variation if !defined $info && !defined $error;
    }
}
if( @available ) {
    output({color=>'cyan',clear=>1}, sprintf "# [%s] Available Variations %d of %d, %0.2f%%",
            $domain,
            scalar(@available),
            scalar(keys %variations),
            100*(scalar(@available) / scalar(keys %variations))
    );
    output({indent=>1,data=>1}, @available);
}
