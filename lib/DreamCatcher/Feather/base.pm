package DreamCatcher::Feather::base;
# ABSTRACT: Base DNS Parsing

use Mouse;
with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::Feather::Sniffer
);
# Packet Parsing
use NetPacket::Ethernet qw(:strip);
use NetPacket::IP qw(:strip :protos);
use NetPacket::UDP;
use NetPacket::TCP;

# Name is
sub _build_name { 'base'; }
# Highest Priority
sub _build_priority { 1; }
# After None, or this loads first
sub _build_after { 'none'; }

sub process {
	my ($self,$packet,$data) = @_;

    # Begin Decoding
    my $ip_pkt  = NetPacket::IP->decode( eth_strip($packet) );

    return unless defined $ip_pkt;
    return unless $ip_pkt->{proto};

    # Transport Layer Processing
    my $layer4 = undef;
    if( $ip_pkt->{proto} == IP_PROTO_UDP ) {
        $layer4 = NetPacket::UDP->decode( $ip_pkt->{data} );
    }
    elsif ( $ip_pkt->{proto} == IP_PROTO_TCP ) {
        $layer4 = NetPacket::TCP->decode( $ip_pkt->{data} );
    }
    else {
        # Bail before referncing this data
        return undef;
    }
    # Set the Succesful Parse
    $data->{_status}{$self->name} = 1;

    # Informations!
    $data->{bytes}     = length $packet;
    $data->{time}      = join('.', $data->{_header}{tv_sec}, sprintf("%0.6d", $data->{_header}{tv_usec}) );
    $data->{src_ip}    = $ip_pkt->{src_ip};
    $data->{dest_ip}   = $ip_pkt->{dest_ip};
    $data->{src_port}  = $layer4->{src_port};
    $data->{dest_port} = $layer4->{dest_port};

    return $layer4;
}

# Return True
1;
