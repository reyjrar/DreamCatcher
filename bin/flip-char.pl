#!perl
#
use v5.40;

my $base = ord('.');
for my $os ( 0..7 ) {
    my $xor = 2 ** $os;
    my $new = chr($base ^ $xor);
    say ". variant '$new'";
}
