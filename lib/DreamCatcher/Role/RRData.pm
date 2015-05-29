package DreamCatcher::Role::RRData;
# ABSTRACT: Provides functions for normalizing RR Data

use Moose::Role;
use namespace::autoclean;

sub rr_data {
	my ($self,$pa) = @_;

	my %data = ( value => undef, opts => undef, ttl => undef );

    my $class = ref $pa;

    if( index($class, 'Net::DNS::RR') >= 0) {
        eval {
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
            # Return True
            1;
        } or eval {
            $data{value} = (split /\s+/, $pa->string)[-1];
        };
        eval { $data{ttl} = $pa->ttl; };
    }
    elsif( $class eq 'Net::DNS::Question' ) {
        $data{value} = defined $pa->zname ? $pa->zname
                     : defined $pa->qname ? $pa->qname
                     : undef;
    }

	return wantarray ? %data : \%data;
}

no Moose::Role;
# Return TRUE
1;
