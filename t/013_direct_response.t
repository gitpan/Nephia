use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use JSON;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;

my $app = Plack::Util::load_psgi('t/nephia-test_app/app.psgi');

test_psgi 
    app => $app,
    client => sub {
        my $cb = shift;

        subtest "normal request" => sub {
            my $res = $cb->(GET "/direct/js");
            is $res->code, 200;
            is $res->content_type, 'text/javascript';
            is $res->content_length, 22;
            is $res->content, 'console.log("foobar");';
        };

        subtest "res by array" => sub {
            my $res = $cb->(GET "/direct/array");
            is $res->code, 200;
            is $res->content, 'foobar';
        };

        subtest "status_code only" => sub {
            my $res = $cb->(GET "/direct/status_code");
            is $res->code, 302;
        };
    }
;

done_testing;
