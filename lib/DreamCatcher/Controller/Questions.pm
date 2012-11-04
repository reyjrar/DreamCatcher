package DreamCatcher::Controller::Questions;
# ABSTRACT: DreamCatcher Question Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    # Queries
    my %sql = (
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
