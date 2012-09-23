package Nephia::Setup;
use strict;
use warnings;
use Class::Load ':all';

sub new {
    my ( $class, %opts ) = @_;
    $opts{flavor} ||= 'Default';

    my $klass = 'Nephia::Setup::'. delete $opts{flavor};
    load_class( $klass );

    return $klass->new( %opts );
}

1;
