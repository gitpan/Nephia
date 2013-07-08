package Nephia::Setup::Git;
use strict;
use warnings;
use File::pushd;

sub additional_methods {
    'git_init',
}

sub git_init {
    my $self = shift;

    {
        my $dir = pushd($self->{approot});
        system ('git', 'init');
        system ('git', 'add', '.');
    }
}

1;
