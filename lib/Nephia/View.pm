package Nephia::View;

use strict;
use warnings;
use Class::Load ':all';

sub new {
    my ( $class, %opts ) = @_;
    $opts{class} ||= 'Xslate';
    my $klass = join '::', __PACKAGE__, delete $opts{class};
    load_class( $klass );
    return $klass->new( %opts );
}

1;
