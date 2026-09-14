#!perl
# PODNAME: domain-typos.pl
# ABSTRACT: Utility for finding typo and spelling mistake domains
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use Net::Whois::Parser;
use Net::Whois::Raw;
use List::Util qw(any);
use Pod::Usage;
use YAML::XS;

# Configure Net::Whois::Raw
$Net::Whois::Raw::OMIT_MSG   = 1;
$Net::Whois::Raw::CHECK_FAIL = 0;
$Net::Whois::Raw::CACHE_DIR  = "$ENV{HOME}/tmp";
$Net::Whois::Raw::TIMEOUT    = 10;

# Options Parsing
my ($opt,$usage) = describe_options(
    "%c %o domain.com",
    [],
    [ 'help|h',    'print this menu and exit'],
    [ 'manual|m',  'print the manual'],
);
pod2usage(-exit=>0,-verbose=>2) if $opt->manual;
output($usage->text) if $opt->help;

my $data;
$data .= $_ while <DATA>;
my $variants = YAML::XS::Load($data);

my @parts = split /\./, shift;
my $tld = pop @parts;
die "not enough parts" unless @parts;
my $domain = join('.', @parts);
my %typos = ();

foreach my $k (keys %{ $variants }) {
    my @vars = split /\s*,/, $variants->{$k};
    foreach my $v (@vars) {
        $typos{$domain =~ s/$k/$v/r} = 1;
        $typos{$domain =~ s/$v/$k/r} = 1;
    }
}

for( my $i = 0; $i < length($domain) -1; $i++) {
    my $c = substr($domain, $i, 1);
    my $d = substr($domain, $i+1, 1);
    my $ent = $domain;
    substr($ent,$i,1) = $d;
    substr($ent,$i+1,1) = $c;
    $typos{$ent} = 1;
}

my %variations = map { $_ => 1 }
                 map { "$_.$tld" }
                 keys %typos;

verbose({level=>2}, "Will check variations:");
verbose({level=>2}, $_) for sort keys %variations;

my $num_variants = scalar keys %variations;
my @available = ();
my @NotFound = split /\n/, <<EOM;
No match for domain
NOT FOUND
Unknown domain name
Object not found
EOM
my $NotFound = join('|', map { quotemeta } @NotFound);
foreach my $variation (keys %variations) {
    my ($raw,$info) = (undef,'');
    eval {
        $raw = whois($variation);
        debug("RAW DATA ($variation): ");
        debug($raw);
    };
    my $error = $@;

    if( defined $raw && $raw =~ /^$NotFound/o ) {
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
            elsif(exists $result->{emails} && defined $result->{emails} ) {
                $info = join( ',', sort grep { defined $_ } @{ $result->{emails} } );
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

    my $color = defined $info  ? 'cyan'
              : defined $error ? 'red'
              : 'green';
    verbose({color=>$color},
        sprintf("Variation %s is %s",
             $variation,
             defined $info  ? "taken ($info)" :
             defined $error ? '!! ERROR !!'   : '** AVAILABLE **'
        ), $error ? $error : (),
    );
    next if defined $error && length $error;

    push @available, $variation if !defined $info;
}
if( @available ) {
    verbose({clear=>1},"# Available variations","");
    output({indent=>1},$_) for sort @available;
    output({clear=>1},sprintf "# Variations %d of %d available (%0.2f%%)", scalar(@available), $num_variants, 100*(scalar(@available) / $num_variants));
}
__DATA__
ie: ei
o: 0,c
q: p,g,c
n: m
r: n
i: l
s: z
v: u
the: teh
