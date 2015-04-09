package DreamCatcher::Controller;

use Mojo::Base qw( Mojolicious::Controller );

use DBIx::Connector;

my $_dbh;

# Database Connection
has dbconn => sub {
    my ($self) = @_;
	if( ! defined $_dbh ) {
		my %c = %{ $self->app->config->{db} };
		$_dbh =  DBIx::Connector->new( @c{qw{dsn user pass}});
	}
	return $_dbh;
};

# Prepare a hash of statements
sub prepare_statements {
    my ($self,$sql) = @_;

    my %sth = ();
    foreach my $s ( keys %{ $sql } ) {
        $sth{$s} = $self->prepare_statement( $sql->{$s} );
    }
    return wantarray ? %sth : \%sth;
}

# Prepare a single statement
sub prepare_statement {
    my ($self,$sql) = @_;

    return $self->dbconn->run( fixup => sub {
        my ($dbh) = @_;
        return $dbh->prepare( $sql );
    });
}

# Common Queries
has common_queries => sub {
    return {
        top_servers => qq{
            select server.id, server.ip as ip, count(1) as clients,
                bool_and(is_authorized) as is_authorized,
                min(conversation.first_ts) as first_ts,
                max(conversation.last_ts) as last_ts,
                sum(conversation.reference_count) as conversations
            from conversation
                inner join server on conversation.server_id = server.id
            where conversation.last_ts > NOW() - interval '30 days'
                group by server.id, server.ip
            order by conversations DESC , clients DESC, first_ts DESC
            limit 200
        },
        top_zones => qq{
            select id, name, reference_count from zone order by reference_count DESC limit 200
        },
        server_responses => q{
            select
                srv.id, srv.ip, r.opcode, r.status, count(1) as queries, sum(count(1)) OVER (PARTITION BY r.server_id) as total
            from response r
                inner join server srv on r.server_id = srv.id
            group by srv.id, r.server_id, r.opcode, r.status
            order by total DESC, queries DESC
            limit 200
        },
        top_questions => qq{
            select r.*, aq.*
                from question r
                left join anomaly_question aq on r.id = aq.id
                order by reference_count DESC limit 200
        },
        recent_questions => qq{
            select * from question
                order by first_ts DESC limit 200
        },
        missed_questions => qq{
            select
                prq.class,
                prq.type,
                prq.name,
                min(prq.first_ts) as first_ts,
                max(prq.last_ts) as last_ts,
                count(1) as misses
            from response pr
                inner join meta_query_response pmqr on pr.id = pmqr.response_id
                inner join meta_question pmq on pmqr.query_id = pmq.query_id
                inner join question prq on pmq.question_id = prq.id
            where pr.status = 'NXDOMAIN'
            group by prq.class, prq.type, prq.name
            order by misses DESC
            limit 200
        },
    };
};

# Prepare a common query and stash it
sub common_query {
    my ($self,$query, @parms) = @_;

    return unless exists $self->common_queries->{$query};

    $self->stash->{STH} = {} unless exists $self->stash->{STH};
    $self->stash->{STH}{$query} = $self->prepare_statement( $self->common_queries->{$query} );
    $self->stash->{STH}{$query}->execute(@parms);
}

# Return true
1;
