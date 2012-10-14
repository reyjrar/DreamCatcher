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
        $sth{$s} = $self->dbconn->run( fixup => sub {
            my ($dbh) = @_;
            return $dbh->prepare( $sql->{$s} );
        });
    }
    return wantarray ? %sth : \%sth;
}


# Return true
1;
