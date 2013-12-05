package DreamCatcher::Controller::Questions;
# ABSTRACT: DreamCatcher Question Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    # Load some common queries
    $self->common_query( $_ ) for qw{top_questions recent_questions missed_questions};

    $self->render();
}

1;
