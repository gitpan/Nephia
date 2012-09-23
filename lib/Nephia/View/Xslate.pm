package Nephia::View::Xslate;
use strict;
use warnings;
use Text::Xslate;

sub new {
    my ( $class, %opts ) = @_;
    $opts{path} ||= [ "$FindBin::Bin/view" ];
    return Text::Xslate->new( %opts );
}

1;
