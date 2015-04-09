package DreamCatcher::Role::Anomaly::Query;

use Moose::Role;

has 'src_table' => (
    is => 'ro',
    default => 'packet_query',
);

# Return True
1;
