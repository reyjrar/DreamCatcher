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


# Return true
1;
