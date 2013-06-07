package Nephia::ClassLoader;
use strict;
use warnings;
use File::Spec;

our %loaded = ();

sub load {
    my ($class, $subclass) = @_;
    unless ($loaded{$subclass}) {
        $loaded{$subclass} = require File::Spec->catfile(split('::', $subclass.'.pm'));
    }
}

sub is_loaded {
    my ($class, $subclass) = @_;
    $loaded{$subclass};
}

1;
