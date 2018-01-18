package DreamCatcher::Helpers;
# ABSTRACT: Mojolicious Helpers for DreamCatcher
use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Const::Fast;
use HTML::Entities;

const my %helpers => (
    make_badge => \&make_badge,
);

sub register {
    my($self,$app) = @_;
    $app->helper( %helpers );
}

const my %_BADGES => (
    query_status => {
        NOERROR  => 'badge-success',
        NXDOMAIN => 'badge-warning',
        SERVFAIL => 'badge-important',
        REFUSED  => 'badge-important',
    },
);

sub make_badge {
    my ($self,$type,$state) = @_;

    return '' unless defined $state and length $state;

    # Make safe for the ==
    $state = encode_entities( decode_entities ( $state ) );
    return $state unless exists $_BADGES{$type};

    my $class = exists $_BADGES{$type}{$state} ? $_BADGES{$type}{$state} : undef;
    # Make sa
    return defined $class ? sprintf('<span class="badge %s">%s</span>', $class, $state) : $state;
}

# Return True;
1;
