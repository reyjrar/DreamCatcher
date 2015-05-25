package DreamCatcher::Role::Feather::Anomaly;
# ABSTRACT: Role container to handle anomaly scores

use Moose::Role;
use namespace::autoclean;

with 'DreamCatcher::Role::Feather';

use Const::Fast;

const my %OPCODES => (
    # Raw                   # Name
    0      => 'common',     QUERY  => 'common',
    1      => 'obsolete',   IQUERY => 'obsolete',
    2      => 'common',     STATUS => 'common',
    3      => 'unassigned',
    4      => 'common',     NOTIFY => 'common',
    5      => 'common',     UPDATE => 'common',
    6      => 'unassigned',
    7      => 'unassigned',
    8      => 'unassigned',
    9      => 'unassigned',
    10     => 'unassigned',
    11     => 'unassigned',
    12     => 'unassigned',
    13     => 'unassigned',
    14     => 'unassigned',
    15     => 'unassigned',
);
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
    # Abnormal
    URI            => 'abnormal',
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
sub anomaly_opcode {
    my $self = shift;
    my $code = shift;
    return $OPCODES{$code} if exists $OPCODES{$code};
    return;
}

no Moose::Role;
# Return True
1;
