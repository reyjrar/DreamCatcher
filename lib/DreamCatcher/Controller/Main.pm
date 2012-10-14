package DreamCatcher::Controller::Main;
# ABSTRACT: DreamCatcher Front Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    my %sql = (
        servers => qq{
			select server.id, server.ip as ip, count(1) as clients, max(conversation.last_ts) as last_ts
   				from conversation
			  		inner join server on conversation.server_id = server.id
				where conversation.last_ts > NOW() - interval '15 days'
					group by server.id, server.ip
        },
        top_zones => qq{
            select id, name, reference_count from zone order by reference_count DESC limit 100
        },
        top_questions => qq{
            select * from packet_record_question
                order by reference_count DESC limit 100
        },
        recent_questions => qq{
            select * from packet_record_question
                order by first_ts DESC limit 100
        },

    );

    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute() for keys %{ $STH };
    # Stash
    $self->stash( STH => $STH );

    $self->render();
}

1;
