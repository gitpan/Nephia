package Nephia::GlobalVars;

use strict;
use warnings;
use utf8;

our $STORED_DATA ||= {};

sub set {
    my ($class, %data) = @_;
    $STORED_DATA = {%$STORED_DATA, %data};
}

sub get {
    my ($class, @keys) = @_;
    my @res = map { $STORED_DATA->{$_} } @keys;
    return wantarray ? @res : $res[0];
}

sub delete {
    my ($class, @keys) = @_;
    for my $key (@keys) {
        delete $STORED_DATA->{$key};
    }
}

1;
