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

sub get_version {
    my $class = shift;
    my $version;
    {
        use Nephia ();
        $version = $Nephia::VERSION;
        no Nephia;
    };
    return $version;
}

1;
