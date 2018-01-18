use Mojo::Base -strict;

use Test::More tests => 3;
use Test::Mojo;

SKIP: {
    skip "config is broken", 3;
    my $t = Test::Mojo->new('DreamCatcher');
    $t->get_ok('/')->status_is(200)->content_like(qr/DreamCatcher/);
};
