package DreamCatcher::Controller::Main;
# ABSTRACT: DreamCatcher Front Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    my %sql = (
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

    # Load some common queries
    $self->common_query( $_ ) for qw{top_servers};

    $self->render();
}

1;
