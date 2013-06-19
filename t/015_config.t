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
        my $expected = +{
            view => {
                include_path => [ 't/nephia-test_app/view' ],
            },
        };

        subtest "config_fetch_test" => sub {
            my $res = $cb->(GET "/configtest");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            is $res->content_length, 52;
            my $json = JSON->new->utf8->decode( $res->content );
            is_deeply $json, $expected;
        };
    }
;

done_testing;
