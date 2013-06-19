use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;
use utf8;
use Encode;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::ParentApp;
use t::Util;

test_psgi
    app => Nephia::ParentApp->run( test_config ),
    client => sub {
        my $cb = shift;
        subtest "parent app" => sub {
            my $res = $cb->(GET "/");
            is $res->code, 200;
            is $res->content, 'this location in parent_app.';
        };

        subtest "sub app" => sub {
            my $res = $cb->(GET "/subapp");
            is $res->code, 200;
            is $res->content, 'this location in sub_app.';
        };

        subtest "child app" => sub {
            my $res = $cb->(GET "/childapp");
            is $res->code, 200;
            is $res->content, 'this location in child_app.';
        };
    }
;

done_testing;
