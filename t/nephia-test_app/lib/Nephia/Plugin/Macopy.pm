package Nephia::Plugin::Macopy;
use strict;
use warnings;
use Encode;

our @EXPORT = qw/wei/;

our $OPT;
sub load {
    my ($class, $pkg, $opt) = @_;
    $OPT = $opt;
}

sub wei {
    return [200, [], [encode_utf8($OPT->{wei})]];
}

1;
