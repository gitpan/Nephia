package Nephia::ParentApp::ChildApp;
use strict;
use warnings;
use utf8;

use Nephia;

path '/' => sub {
    res {
        body ('this location in child_app.')
    };
};



1;

