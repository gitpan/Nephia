use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;
use t::Util;

test_psgi 
    app => Nephia::TestApp->run( test_config ),
    client => sub {
        my $cb = shift;

        subtest "normal request" => sub {
            my $res = $cb->(GET "/direct/js");
            is $res->code, 200;
            is $res->content_type, 'text/javascript';
            is $res->content_length, 22;
            is $res->content, 'console.log("foobar");';
        };
    }
;

done_testing;
