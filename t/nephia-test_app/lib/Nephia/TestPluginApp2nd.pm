package Nephia::TestPluginApp2nd;
use strict;
use warnings;
use utf8;
use Nephia plugins => ['Moz' => {word => 'kieeeee'}];

path '/' => sub {
    my $req     = req;
    my $param   = param('foo');
    my $appname = appname;
    return {
        message => '八王子なう',
        params  => $param,
        appname => $appname,
    };
};

1;
