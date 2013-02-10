package DreamCatcher::Role::RRData;
# ABSTRACT: Provides functions for normalizing RR Data

use Moo::Role;
use CHI;

sub rr_data {
	my ($self,$pa) = @_;

	my %data = ( value => undef, opts => undef );

	if( $pa->type eq 'A' || $pa->type eq 'AAAA' ) {
		$data{value} = $pa->address;
	}
	elsif( $pa->type eq 'CNAME' ) {
		$data{value} = $pa->cname;
	}
	elsif( $pa->type eq 'DNAME' ) {
		$data{value} = $pa->dname;
	}
	elsif( $pa->type eq 'MX' ) {
		$data{value} = $pa->exchange;
		$data{opts} = $pa->preference;
	}
	elsif( $pa->type eq 'NS' ) {
		$data{value} = $pa->nsdname;
	}
	elsif( $pa->type eq 'PTR' ) {
		$data{value} = $pa->ptrdname;
	}
	elsif( $pa->type eq 'SRV' ) {
		$data{value} = $pa->target;
		$data{value} .= ':' . $pa->port if $pa->port;
		$data{opts} = $pa->priority;
		$data{opts} .= ';' . $pa->priority if defined $pa->weight;
	}
	elsif( $pa->type eq 'SPF' || $pa->type eq 'TXT' ) {
		$data{value} = $pa->txtdata;
	}

	return wantarray ? %data : \%data;
}
# Return TRUE
1;
