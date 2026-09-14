#!perl
#
use v5.40;
use CLI::Helpers qw(:output);

my @TLDS = ();
while(<<>>) {
    chomp;
    next unless length;
    next if /^#/;
    push @TLDS, lc $_;
}

my %TLDS = map { $_ => 1 } @TLDS;
my %VALID = map { $_ => 1 } split '', q{ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.};

foreach my $tld ( @TLDS ) {
    my @variants = ();
    for my $place ( 0 .. length($tld)-1 ) {
        my $letter = substr($tld,$place,1);

        my %valid = %VALID;
        delete $valid{'-'} if $place == 0 || $place == length($tld)-1;

        my $base = ord($letter);
        for my $os ( 0..7 ) {
            my $xor = 2 ** $os;
            my $new = chr($base ^ $xor);
            next unless exists $valid{$new};
            my $copy = $tld;
            substr($copy,$place,1,$new);
            my $variation = lc $copy;
            push @variants, $variation if $TLDS{$variation} && $variation ne $tld;
        }
    }
    if ( @variants ) {
        output({color=>'cyan'}, "TLD=$tld, variants " . join(', ', @variants));
    }
}
