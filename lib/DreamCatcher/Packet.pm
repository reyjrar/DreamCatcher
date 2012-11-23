package DreamCatcher::Packet;

# ABSTRACT: DreamCatcher Packet Parsing object
use Mouse;

# Packet Parsing
use NetPacket::Ethernet qw(:strip);
use NetPacket::IP qw(:strip :protos);
use NetPacket::UDP;
use NetPacket::TCP;
use Try::Tiny;

# DNS Decoding
use Net::DNS::Packet;

# The Raw Packet off the wire
has 'raw_packet' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    init_arg => 'Packet',
);
# Process the packet, ready for other attributes
has 'raw_data' => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_raw_data',
);
# Is the packet valid
has 'valid' => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_valid',
);
# Details Extracted by BUILD
has 'details' => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_details',
);
# Net::DNS::Packet Object
has 'dns' => (
    is       => 'ro',
    isa      => 'Object',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_dns',
);
# Errors with this packet
has 'error' => (
    is       => 'ro',
    isa      => 'Defined',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_error',
);
# If just a packet is sent, we set the Packet parameter
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if( @_ == 1 && ref $_[0] ne 'HASH' ) {
        return $class->$orig( Packet => $_[0] );
    }
    return $class->$orig( @_ );
};

# BUILDERS FOR ATTRIBUTES
sub _get_data {
    my $self = shift;
    my $field = shift;
    my $data = $self->raw_data();
    return exists $data->{$field} ? $data->{$field} : undef;
}
sub _build_valid {
    my $self = shift;
    return $self->_get_data( 'valid' );
}
sub _build_details {
    my $self = shift;
    return $self->_get_data( 'details' );
}
sub _build_dns {
    my $self = shift;
    return $self->_get_data( 'dns' );
}
sub _build_error {
    my $self = shift;
    return $self->_get_data( 'error' );
}
sub _build_raw_data {
	my $self = shift;
    my %data = (
        details => undef,
        dns     => undef,
        valid   => 0,
    );

    # Begin Decoding
    my ($hdr,$packet) = @{ $self->raw_packet() };
    my $ip_pkt  = NetPacket::IP->decode( eth_strip($packet) );

    return { %data, error => "NetPacket decode failed!" } unless defined $ip_pkt;
    return { %data, error => "NetPacket decode failed, no protocol!" } unless $ip_pkt->{proto};

    # Transport Layer Processing
    my $layer4 = undef;
    if( $ip_pkt->{proto} == IP_PROTO_UDP ) {
        $layer4 = NetPacket::UDP->decode( $ip_pkt->{data} );
        $data{details}->{proto} = 'udp';
    }
    elsif ( $ip_pkt->{proto} == IP_PROTO_TCP ) {
        $layer4 = NetPacket::TCP->decode( $ip_pkt->{data} );
        $data{details}->{proto} = 'tcp';
    }
    else {
        # Bail before referncing this data
        return { %data, error => "Decode failed, not TCP or UDP" };
    }

    # Informations!
    $data{details}->{bytes}     = length $packet;
    $data{details}->{time}      = join('.', $hdr->{tv_sec}, sprintf("%0.6d", $hdr->{tv_usec}) );
    $data{details}->{src_ip}    = $ip_pkt->{src_ip};
    $data{details}->{dest_ip}   = $ip_pkt->{dest_ip};
    $data{details}->{src_port}  = $layer4->{src_port};
    $data{details}->{dest_port} = $layer4->{dest_port};

    # Parse DNS Packet
    my $dnsp = undef;
    try {
        $dnsp = Net::DNS::Packet->new( \$layer4->{data} );
    };
    return { %data, error => "Net::DNS unable to parse DNS Packet" } unless defined $dnsp;

    # Server Accounting.
    $data{details}->{qa} = $dnsp->header->qr ? 'answer' : 'question';

    if( $data{details}->{qa} eq 'answer' ) {
        $data{details}->{server}      = $data{details}->{src_ip};
        $data{details}->{server_port} = $data{details}->{src_port};
        $data{details}->{client}      = $data{details}->{dest_ip};
        $data{details}->{client_port} = $data{details}->{dest_port};
    }
    else {
        $data{details}->{server}      = $data{details}->{dest_ip};
        $data{details}->{server_port} = $data{details}->{dest_port};
        $data{details}->{client}      = $data{details}->{src_ip};
        $data{details}->{client_port} = $data{details}->{src_port};
    }

    $data{valid} = 1;
    $data{dns} = $dnsp;

    return \%data;
}

# Return True
1;
