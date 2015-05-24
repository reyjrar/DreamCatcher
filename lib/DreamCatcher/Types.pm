package DreamCatcher::Types;

use MooseX::Types -declare => [qw(
    PositiveInt
)];

use MooseX::Types::Moose qw(Int);

subtype PositiveInt,
    as Int,
    where { $_ > 0 },
    message { "Must be a positive integer." };
