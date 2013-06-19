use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use JSON;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;
use t::Util;

my $app = Plack::Util::load_psgi('t/nephia-test_app/app.psgi');

test_psgi 
    app => $app,
    client => sub {
        my $cb = shift;

        subtest "normal request" => sub {
            my $res = $cb->(GET "/");
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content_length, 211;
            like $res->content, qr/Nephia::TestApp/;
        };
    }
;

done_testing;
