#!perl
# PODNAME: domain-typos.pl
# ABSTRACT: Utility for finding typo and spelling mistake domains
use v5.40;
use utf8;
use open qw< :std :encoding(UTF-8) >;

use Algorithm::Combinatorics qw(combinations permutations);
use Algorithm::Permute qw(permute);
use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use Net::IDN::Encode qw(domain_to_ascii);
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
    [ 'all', "Use all variants, not just the most believable" ],
    [ 'replacements|r=i', "Number of characters to replace with Unicode", { default => 1 }, ],
    [],
    [ 'help|h',    'print this menu and exit'],
    [ 'manual|m',  'print the manual'],
    { show_defaults => 1},
);
pod2usage(-exit=>0,-verbose=>2) if $opt->manual;
output($usage->text) if $opt->help;

# Ordered such that first element is most believable
my %IDENTICAL = (
    a => [qw( а )],
    c => [qw( с  )],
    d => [qw( ԁ )],
    e => [qw( е ẹ )],
    h => [qw( һ )],
    i => [qw( і )],
    j => [qw( ј )],
    n => [qw( ո )],
    o => [qw( о ο օ )],
    p => [qw( р )],
    q => [qw( զ )],
    u => [qw( υ ս )],
    v => [qw( ν )],
    x => [qw( х ҳ )],
    y => [qw( у )],
);

my %ALL = (
    a => [qw( а ạ ą ä à á ą )],
    c => [qw( с ƈ ċ )],
    d => [qw( ԁ ɗ )],
    e => [qw( е ẹ ė é è )],
    g => [qw( ġ )],
    h => [qw( һ )],
    i => [qw( і í ï )],
    j => [qw( ј ʝ )],
    k => [qw( κ )],
    l => [qw( ӏ ḷ )],
    n => [qw( ո )],
    o => [qw( о ο օ ȯ ọ ỏ ơ ó ò ö )],
    p => [qw( р )],
    q => [qw( զ )],
    s => [qw( ʂ )],
    u => [qw( υ ս ü ú ù )],
    v => [qw( ν ѵ )],
    x => [qw( х ҳ )],
    y => [qw( у ý )],
    z => [qw( ʐ ż  )],
);

my %PUNYCODE = $opt->all ? %ALL : %IDENTICAL;

my @parts = split /\./, shift;
my $TLD = pop @parts;
die "not enough parts" unless @parts;
my $DOMAIN = join('.', @parts);
my $PUNYCHARS = sprintf "[%s]", join('', sort keys %PUNYCODE);

# Check for variations
my @AllMutations = ();
my $Possible = calculate_total_variations();

foreach my $dom (@AllMutations) {
    my $puny = domain_to_ascii($dom, AllowUnassigned => 1);
    next if $puny eq $dom;
    say "$dom is $puny";
}

exit;
sub expand_mutations {
    my ($domain, $mutations) = @_;
    $mutations ||= [];

    # Base case
    return unless @{ $mutations };

    my $mut = shift @{ $mutations };

    foreach my $char ( @{ $mut->{set} } ) {
        my $ld = $domain;
        substr($ld, $mut->{pos} - 1, 1, $char);
        push @AllMutations, $ld . ".$TLD";
        expand_mutations($ld, $mutations);
    }
}

sub calculate_total_variations() {
    my(@chars, @offsets);
    while ( $DOMAIN =~ /($PUNYCHARS)/gi ) {
        push @chars, $1;
        push @offsets, pos($DOMAIN)
    }
    my $chars = @chars;

    if ( $chars < 1 ) {
        output({color=>'green'}, "No easy punycode attack for $DOMAIN.$TLD");
        exit 0;
    }

    my $possible = 1;
    my %variants = map { $_ => scalar(@{ $PUNYCODE{$_} }) } @chars;
    foreach my $char ( @chars ) {
        # This position can have punycode or ascii, so add one to the variation
        $possible *= $variants{$char} + 1;
    }
    $possible--; # remove the ansi-only version

    # Calculate the total possible variation
    my $total = 0;
    my $max = $opt->replacements > @chars ? @chars : $opt->replacements;
    my @mutations = ();
    foreach my $n ( 1..$max ) {
        my $c = combinations(\@offsets, $n);
        my $nt = 0;
        while ( my $set = $c->next ) {
            my $t = 1;
            my @mut;
            foreach my $pos ( @{ $set } ) {
                my $char = substr $DOMAIN, $pos -1, 1;
                $t *= $variants{$char};
                push @mut, { pos => $pos, set => [ $char, @{ $PUNYCODE{$char} } ] };
            }
            push @mutations, \@mut;
            $nt += $t;
        }
        $total += $nt;
    }

    foreach my $mut (@mutations) {
        expand_mutations($DOMAIN,$mut);
    }

    output({color=>"yellow"},
        sprintf "Domain=%s.%s : %d viable positions, %d variants using %d replacements, %d total variations",
            $DOMAIN, $TLD,
            $chars,
            $total, $max,
            $possible,
    );

    return $possible;
}
