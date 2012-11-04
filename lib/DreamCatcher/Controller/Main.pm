package DreamCatcher::Controller::Main;
# ABSTRACT: DreamCatcher Front Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    # Load some common queries
    $self->common_query( $_ ) for qw{top_servers top_zones};

    $self->render();
}

1;
