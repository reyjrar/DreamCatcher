package DreamCatcher::Feather::dns;
# ABSTRACT: Extract basic DNS information from the packet

use strict;
use warnings;
use Net::DNS::Packet;
use Mouse;
with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::Feather::Sniffer
);

# Override default priority
sub _build_priority { 2; }

sub process {
    my ($self,$packet,$data) = @_;

    # Parse DNS Packet
    my $dnsp = Net::DNS::Packet->new( $packet->{data} );
    return unless defined $dnsp;

    #
    # Server Accounting.
    $data->{qa} = $dnsp->header->qr ? 'answer' : 'question';

    if( $data->{qa} eq 'answer' ) {
        $data->{server}      = $data->{src_ip};
        $data->{server_port} = $data->{src_port};
        $data->{client}      = $data->{dest_ip};
        $data->{client_port} = $data->{dest_port};
    }
    else {
        $data->{server}      = $data->{dest_ip};
        $data->{server_port} = $data->{dest_port};
        $data->{client}      = $data->{src_ip};
        $data->{client_port} = $data->{src_port};
    }

    # Return the DNS Packet
    return $dnsp;
}

# Return True;
1;
