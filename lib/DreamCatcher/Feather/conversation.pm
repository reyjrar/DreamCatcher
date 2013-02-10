package DreamCatcher::Feather::conversation;
# ABSTRACT: Determine which conversation this packet belongs to.

use strict;
use warnings;
use Moo;

with qw(
    DreamCatcher::Role::Feather
	DreamCatcher::Role::DBH
);

# Override default priority
sub _build_priority { 1; }

sub process {
    my ($self,$packet) = @_;

    # Conversations
	my $dbError = undef;
	my $sth = $self->dbh->run( fixup => sub {
			my $sth = $_->prepare('select * from find_or_create_conversation( ?, ? )');
			$sth->execute( $packet->details->{client}, $packet->details->{server} );
			$sth;
		}, catch {
			$dbError = "find_or_create_conversation failed: $_";
		}
	);

	if( !defined $dbError && $sth->rows > 0 ) {
		# Set conversation id
		my $convo = $sth->fetchrow_hashref;
		$packet->details->{client_id} = $convo->{client_id};
		$packet->details->{server_id} = $convo->{server_id};
		$packet->details->{conversation_id} = $convo->{conversation_id};
	}
}

# Return True;
1;
