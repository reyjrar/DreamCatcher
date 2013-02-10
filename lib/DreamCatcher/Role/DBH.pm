package DreamCatcher::Role::DBH;
# ABSTRACT: Provides the database connection for the feathers

use Moo::Role;
use DBIx::Connector;

requires qw(config);

has 'dbh' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_dbh',
);

sub _build_dbh {
	my ($self) = @_;

	die "No db section in config!" unless exists $self->config->{db} && ref $self->config->{db} eq 'HASH';

	my %db = %{ $self->config->{db} };
	return DBIx::Connector->new( @db{qw(dsn user pass)}, { RaiseError => 0 });
}

# Return TRUE
1;
