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
                min(conversation.first_ts) as first_ts,
                max(conversation.last_ts) as last_ts,
                sum(conversation.reference_count) as conversations
            from conversation
                inner join server on conversation.server_id = server.id
            where conversation.last_ts > NOW() - interval '15 days'
                group by server.id, server.ip
        },
    };
};

# Prepare a common query and stash it
sub common_query {
    my ($self,$query, @parms) = @_;



    do { warn "fuck me"; return } unless exists $self->common_queries->{$query};

    $self->stash->{STH} = {} unless exists $self->stash->{STH};
    $self->stash->{STH}{$query} = $self->prepare_statement( $self->common_queries->{$query} );
    $self->stash->{STH}{$query}->execute(@parms);
}

# Return true
1;
