package DreamCatcher::Controller::Main;
# ABSTRACT: DreamCatcher Front Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    $self->render();
}

1;
