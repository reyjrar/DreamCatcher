package DreamCatcher::Role::Feather::Anomaly;
# ABSTRACT: Role container to handle anomaly scores

use Moose::Role;
use namespace::autoclean;

with 'DreamCatcher::Role::Feather';

use Const::Fast;

const my %RR_TYPES => (
    # Common
    A              => 'common',
    AAAA           => 'common',
    CAA            => 'common',
    CNAME          => 'common',
    DLV            => 'common',
    DNSKEY         => 'common',
    DNAME          => 'common',
    DS             => 'common',
    KEY            => 'common',
    MX             => 'common',
    NS             => 'common',
    PTR            => 'common',
    RRSIG          => 'common',
    SOA            => 'common',
    SIG            => 'common',
    SPF            => 'common',
    SRV            => 'common',
    SSHFP          => 'common',
    TA             => 'common',
    TKEY           => 'common',
    TSIG           => 'common',
    # Obsolete
    A6             => 'obsolete',
    MAILA          => 'obsolete',
    MAILB          => 'obsolete',
    MD             => 'obsolete',
    MF             => 'obsolete',
    MINFO          => 'obsolete',
    # Suspicious
    ANY            => 'suspicious',
    AXFR           => 'suspicious',
    IXFR           => 'suspicious',
    HINFO          => 'suspicious',
    # Experimental
    MB             => 'experimental',
    MG             => 'experimental',
    MR             => 'experimental',
    NULL           => 'experimental',
);

const my %CLASSES => (
    IN => 'common',
    # Obsolete
    CH => 'obsolete',
    HS => 'obsolete',
);

# Attributes

has 'scores' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_scores',
    init_arg => undef,
);

# Builders

sub _build_scores {
    return {
        abnormal     => 10,
        obsolete     => 10,
        mismatch     => 15,
        unassigned   => 15,
        private      => 20,
        experimental => 30,
        suspicious   => 50,
        malicious    => 100,
    };
}

# Methods
sub score {
    my $self = shift;
    my $type = shift;
    return exists $self->scores->{$type} ? $self->scores->{$type} : 5;
}

sub anomaly_class {
    my $self  = shift;
    my $class = shift;
    return $CLASSES{$class} if exists $CLASSES{$class};
    return;
}

sub anomaly_type {
    my $self = shift;
    my $type = shift;
    return $RR_TYPES{$type} if exists $RR_TYPES{$type};
    return;
}

no Moose::Role;
# Return True
1;
