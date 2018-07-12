#!perl
# PODNAME: domain-jumble.pl
# ABSTRACT: Utility for combining words and checking the availability of domains.
use strict;
use warnings;

use Algorithm::Permute qw(permute);
use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use Net::Whois::Parser;
use Net::Whois::Raw;
use List::Util qw(any);
use Pod::Usage;

# Configure Net::Whois::Raw
$Net::Whois::Raw::OMIT_MSG   = 1;
$Net::Whois::Raw::CHECK_FAIL = 0;
$Net::Whois::Raw::CACHE_DIR  = "$ENV{HOME}/tmp";
$Net::Whois::Raw::TIMEOUT    = 10;

# Options Parsing
my ($opt,$usage) = describe_options(
    "%c %o [list of optional words to include]",
    [],
    [ 'tlds:s',                "Comma separated list of TLDs to search    (Default: 'com,net')", {default => 'com,net'} ],
    [ 'required|r:s',          "Comma separated list of required words", ],
    [ 'maxwords|n:i',          "Maximum number of words to allow,         (Default: 4)",         {default => 4}, ],
    [ 'exclusive|e:s',         "Comma separated list of exclusive required words", ],
    [ 'separator|seperator:s', "String to use to separate words           (Default: -)",         {default => '-'},],
    [],
    [ 'help|h',    'print this menu and exit'],
    [ 'manual|m',  'print the manual'],
);
pod2usage(-exit=>0,-verbose=>2) if $opt->manual;
output($usage->text) if $opt->help;

my $domain;
my $max_words = $opt->maxwords;
$max_words = 2 if $max_words < 2;
my @TLDS = split /\,/, $opt->tlds;
my %Required = defined $opt->required ? map { $_ => 1 } split(',', $opt->required) : ();
my %words = map { lc($_) => 1 } map { split ','; } @ARGV, keys %Required;
my @words = sort keys %words;
my %variations;

if(defined $opt->exclusive) {
    foreach my $word (split ',', $opt->exclusive) {
        $Required{$word} ||= 0;
        $Required{$word}++;
        @variations{build_list(@words,$word)} = ();
        delete $Required{$word} unless --$Required{$word};
    }
}
else {
    @variations{build_list(@words)} = ();
}
verbose({level=>2}, "Will check variations:");
verbose({level=>2}, $_) for sort keys %variations;

sub build_list {
    my @words = @_;
    my %collected = ();
    for(my $i=0; $i < @words; $i++ ) {
        my $key = $words[$i];
        my @subset = ();
        foreach my $other (@words) {
            next if $other eq $words[$i];
            push @subset, $other;

            shift @subset if @subset == $max_words;

            if( keys %Required && !exists $Required{$key}) {
                next unless any { exists $Required{$_} } @subset;
            }

            push @subset, $key;
            permute { my $name=join($opt->separator, @subset); $collected{"$name.$_"}=1 for @TLDS; } @subset;
            pop @subset;
        }
    }
    return keys %collected;
}
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
__END__
=pod

=head1 SYNOPSIS

domain-jumble.pl [options]

See

    domain-jumble.pl --help

For a list of options

=head1 DESCRIPTION

This tool allows you to transform a list of words into a list of possible domain names with some intelligence
and check the availability of those domains using whois.

=head2 EXAMPLES

To check for domains which require the word "apple" and optionally have the words "rotten" or "fresh":


    domain-jumble.pl --tlds com --require apple rotten fresh

Looks for:

    apple-fresh-rotten.com
    apple-rotten-fresh.com
    apple-rotten.com
    fresh-apple-rotten.com
    fresh-apple.com
    fresh-rotten-apple.com
    rotten-apple-fresh.com
    rotten-apple.com
    rotten-fresh-apple.com

If you want to have "fresh" or "rotten" match exclusively:

    domain-jumble.pl --tlds com --require apple --exclusive fresh,rotten

Will look for:

    apple-fresh.com
    apple-rotten.com
    fresh-apple.com
    rotten-apple.com

Add fruit as an optional parameter:

    domain-jumble.pl --tlds com --require apple --exclusive fresh,rotten fruit

Will check:

    apple-fresh-fruit.com
    apple-fresh.com
    apple-fruit-fresh.com
    apple-fruit-rotten.com
    apple-fruit.com
    apple-rotten-fruit.com
    apple-rotten.com
    fresh-apple-fruit.com
    fresh-apple.com
    fresh-fruit-apple.com
    fruit-apple-fresh.com
    fruit-apple-rotten.com
    fruit-apple.com
    fruit-fresh-apple.com
    fruit-rotten-apple.com
    rotten-apple-fruit.com
    rotten-apple.com
    rotten-fruit-apple.com

You can also specify --maxwords to limit how many words to join together, the default is 4:

    domain-jumble.pl --tlds com --maxwords 2 --require apple --exclusive fresh,rotten fruit

Will now only look for:

    apple-fresh.com
    apple-fruit.com
    apple-rotten.com
    fresh-apple.com
    fruit-apple.com
    rotten-apple.com

Adjust options as necessary, caches used as available.
