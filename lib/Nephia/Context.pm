package Nephia::Context;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, %opts) = @_;
    bless {%opts}, $class;
}

sub set {
    my ($self, %opts) = @_;
    for my $key (%opts) {
        $self->{$key} = $opts{$key};
    }
}

sub get {
    my ($self, @keys) = @_;
    my @res = map { $self->{$_} } @keys;
    return wantarray ? @res : $res[0];
}

1;
