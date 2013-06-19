package Nephia::SubApp;
use strict;
use warnings;
use utf8;

use Nephia;

path '/' => sub {
    res {
        body ('this location in sub_app.')
    };
};


1;

