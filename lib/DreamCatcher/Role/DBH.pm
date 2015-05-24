package DreamCatcher::Role::DBH;
# ABSTRACT: Provides the database connection for the feathers

use Moose::Role;
use namespace::autoclean;

use DBIx::Connector;
use Exception::Class::DBI;

with qw(
    DreamCatcher::Role::Logger
    DreamCatcher::Role::Cache
);

has 'dbh' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_dbh',
    init_arg => undef,
);

has 'sql' => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_sql',
);

sub _build_sql { {} }

sub sth {
    my ($self,$name) = @_;

    if( !exists $self->sql->{$name} ) {
        $self->log(error => "attempt to load unknown statement:$name");
        return;
    }

    return $self->dbh->run( fixup => sub {
        my $sth;
        eval {
            $self->log(debug => "preparing $name");
            $sth = $_->prepare( $self->sql->{$name} );
        };
        if( my $err = $@ ) {
            $self->log( error => join(" - ", ref $err, $err->errstr ));
        }
        return $sth;
    });
}

sub _build_dbh {
	my ($self) = @_;

	die "No db section in config!" unless exists $self->config->{db} && ref $self->config->{db} eq 'HASH';

	my %db = %{ $self->config->{db} };
	my $dbconn = DBIx::Connector->new( @db{qw(dsn user pass)}, {
            PrintError  => 0,
            RaiseError  => 0,
            HandleError => Exception::Class::DBI->handler,
    });
    if( !defined $dbconn ) {
        $self->log( fatal => "Database setup failed" );
        die "DB setup failed";
    }
    $self->log( debug => "Database established" );
    return $dbconn;
}

no Moose::Role;
# Return TRUE
1;
