package Nephia::View;

use strict;
use warnings;
use Nephia::ClassLoader;

sub new {
    my ( $class, %opts ) = @_;
    $opts{class} ||= 'MicroTemplate';
    my $subclass = join '::', __PACKAGE__, delete $opts{class};
    Nephia::ClassLoader->load( $subclass );
    return $subclass->new( %opts );
}

1;
