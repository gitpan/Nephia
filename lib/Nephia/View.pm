package Nephia::View;

use strict;
use warnings;
use Module::Load ();

sub new {
    my ( $class, %opts ) = @_;
    $opts{class} ||= 'MicroTemplate';
    my $subclass = join '::', __PACKAGE__, delete $opts{class};

    Module::Load::load($subclass);
    return $subclass->new( %opts );
}

1;
