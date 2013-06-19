package Nephia::ParentApp;
use strict;
use warnings;
use utf8;

use Nephia;

path '/' => sub {
    res {
        body ('this location in parent_app.')
    };
};

path '/subapp' => 'Nephia::SubApp';
path '/childapp' => '+ChildApp';

1;

