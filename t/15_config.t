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

        subtest "config_fetch_test" => sub {
            my $res = $cb->(GET "/configtest");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            is $res->content_length, 44;
            my $json = JSON->new->utf8->decode( $res->content );
            is_deeply $json, { test_config() };
        };
    }
;

done_testing;
