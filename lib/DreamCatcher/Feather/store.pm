package DreamCatcher::Feather::store;
# ABSTRACT: Store the DNS packet in the database.

use strict;
use warnings;
use Moo;

with qw(
    DreamCatcher::Role::Feather
	DreamCatcher::Role::Logger
	DreamCatcher::Role::DBH
	DreamCatcher::Role::Cache
	DreamCatcher::Role::RRData
);

sub _build_parent { 'conversation'; }

# Queries we'd like the cache
sub _build_sql {
    return {
   		query         => q{select add_query( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )},
   		question      => q{select find_or_create_question( ?, ?, ?, ? ) },
   		response      => q{select add_response( ?, ?, ?, ?, ?, ?, ?,
                                                ?, ?, ?, ?, ?, ?, ?,
                                                ?, ?, ?, ?, ?, ? )},
   		answer         => q{select find_or_create_answer( ?, ?, ?, ?, ?, ?, ?, ? )},
   		query_response => q{select link_query_response( ?, ? )},
    };
}

sub process {
	my ( $self,$packet ) = @_;

	# Packet ID
    my $dnsp = $packet->dns;
    my $info = $packet->details;
	my $packet_id = join(';', $info->{conversation_id}, $dnsp->header->id );

	# Check for query/response
	if( $dnsp->header->qr ) {
		# Grab Queriy id from cache:
		my $query_id = $self->cache->get( $packet_id );
		# Answer
        my $sth = $self->sth('response');
		$sth->execute(
			$info->{conversation_id},
			$info->{client_id},
			$info->{client_port},
			$info->{server_id},
			$info->{server_port},
			$dnsp->header->id,
			$dnsp->header->opcode,
			$dnsp->header->rcode,
			$dnsp->answersize,
			$dnsp->header->ancount,
			$dnsp->header->arcount,
			$dnsp->header->nscount,
			$dnsp->header->qdcount,
			$dnsp->header->aa,
			$dnsp->header->ad,
			$dnsp->header->tc,
			$dnsp->header->cd,
			$dnsp->header->rd,
			$dnsp->header->ra,
			$info->{time},
		);

		my ($response_id) = $sth->fetchrow_array;
		return unless defined $response_id && $response_id > 0;

		# Link Query / Response
		if( defined $query_id ) {
            my $sth_qr = $self->sth('query_response');
			$sth_qr->execute($query_id, $response_id);
		}

		my @sets = ();

		foreach my $section (qw(answer additional authority)) {
			my @records = ();
			eval {
				no strict;
				@records = $dnsp->$section();
			};
			if( @records ) {
				push @sets, { name => $section, rr => \@records };
			}
		}
		foreach my $set ( @sets ) {
			foreach my $pa ( @{ $set->{rr} } ) {
				my %data = $self->rr_data( $pa );

				next unless defined $data{value} && length $data{value};

                my $lsh = $self->sth('answer');
				$lsh->execute(
					$response_id,
					$set->{name},
					$pa->ttl,
					$pa->class,
					$pa->type,
					$pa->name,
					$data{value},
					$data{opts},
				);
			}
		}
	}
	else {
		# Query
        my $sth = $self->sth('query');
		$sth->execute(
			$info->{conversation_id},
			$info->{client_id},
			$info->{client_port},
			$info->{server_id},
			$info->{server_port},
			$dnsp->header->id,
			$dnsp->header->opcode,
			$dnsp->header->qdcount,
			$dnsp->header->rd,
			$dnsp->header->tc,
			$dnsp->header->cd,
			$info->{time},
		);

		my ($query_id) = $sth->fetchrow_array;
		return unless defined $query_id && $query_id > 0;

		# Set Cache:
		$self->cache->set( $packet_id, $query_id );
		foreach my $pq ( $dnsp->question ) {
            my $lsh = $self->sth('question');
			$lsh->execute(
				$query_id,
				$pq->qclass,
				$pq->qtype,
				$pq->qname
			);
		}
	}
}

# Return True;
1;
