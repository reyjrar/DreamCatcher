package DreamCatcher::Feather::store;
# ABSTRACT: Store the DNS packet in the database.

use strict;
use warnings;
use Moose;

with qw(
    DreamCatcher::Role::Feather::Sniffer
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
    };
}

sub process {
	my ( $self,$packet ) = @_;

	# Packet ID
    my $dnsp = $packet->dns;
    my $info = $packet->details;

	# Check for query/response
	if( $dnsp->header->qr ) {
		# Answer
        my $sth = $self->sth('response');
        eval {
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
        };
        if( my $ex = $@ ) {
            $self->log(error => "store failed: $ex->errstr");
            return;
        }

		my ($response_id) = $sth->fetchrow_array;
		return unless defined $response_id && $response_id > 0;


		my @sets = ();
		foreach my $section (qw(answer additional authority pre prerequisite update zone)) {
			my @records = ();
			eval {
				no strict;
				@records = $dnsp->$section();
			};
			if( @records ) {
				push @sets, { name => $section eq 'pre' ? 'prerequisite' : $section, rr => \@records };
			}
		}
		foreach my $set ( @sets ) {
			foreach my $pa ( @{ $set->{rr} } ) {
				my %data = $self->rr_data( $pa );

				next unless defined $data{value} && length $data{value};

                my $lsh = $self->sth('answer');
                eval {
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
                };
                if( my $ex = $@ ) {
                    $self->log(error => "Attempt to create answer failed: $ex->errstr");
                    next;
                }
			}
		}
	}
	else {
		# Query
        my $sth = $self->sth('query');
        eval {
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
        };
        if (my $ex = $@) {
            $self->log(error => "Failed to create query object: $ex->errstr");
            return;
        }

		my ($query_id) = $sth->fetchrow_array;
		return unless defined $query_id && $query_id > 0;

        # Tag questions
		foreach my $pq ( $dnsp->question ) {
            my $lsh = $self->sth('question');
            eval {
                $lsh->execute(
                    $query_id,
                    $pq->qclass,
                    $pq->qtype,
                    $pq->qname
                );
            };
		}
	}
}

__PACKAGE__->meta->make_immutable;
