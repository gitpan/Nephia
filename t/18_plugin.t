use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;
use utf8;
use Encode;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;
use t::Util;

test_psgi 
    app => Nephia::TestApp->run( test_config ),
    client => sub {
        my $cb = shift;
        subtest "bark" => sub {
            my $res = $cb->(GET "/bark");
            is $res->code, 200;
            is $res->content, 'Bark!';
        };

        subtest "barkbark" => sub {
            my $res = $cb->(GET "/barkbark");
            is $res->code, 200;
            is $res->content, 'Bark foo bar';
        };
    }
;

done_testing;
