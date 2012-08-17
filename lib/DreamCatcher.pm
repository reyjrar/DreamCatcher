package DreamCatcher;
use Mojo::Base 'Mojolicious';
# ABSTRACT: DreamCatcher is a DNS Monitoring Suite
our $VERSION = 0.1;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Configure Defaults
  $self->defaults(
        layout => 'bootstrap',
  );

  # Router
  my $r = $self->routes;
  $r->namespace("DreamCatcher::Controller");

  # Normal route to controller
  $r->get('/')->to('main#index');
}

1;
