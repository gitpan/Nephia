package MyApp::Foo;

use strict;
use warnings;
use Nephia;

path '/foo' => sub {
    my $req = shift;
    return res {
        content_type('text/javascript');
        body('alert("hoge");');
    };
};

1;
