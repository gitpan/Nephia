package Nephia::Setup;
use strict;
use warnings;
use Nephia::ClassLoader;

sub new {
    my ( $class, %opts ) = @_;
    $opts{flavor} ||= 'Default';

    my $subclass = 'Nephia::Setup::'. delete $opts{flavor};
    Nephia::ClassLoader->load( $subclass );

    return $subclass->new( %opts );
}

1;
