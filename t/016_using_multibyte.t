use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;
use utf8;
use Encode;

my $app = Plack::Util::load_psgi('t/nephia-test_app/app.psgi');

test_psgi 
    app => $app,
    client => sub {
        my $cb = shift;

        subtest "UTF-8" => sub {
            my $res = $cb->(GET "/nihongo");
            is $res->code, 200;
            is $res->content_type, 'text/html';
            is $res->content_length, 223;
            my $str = Encode::encode( 'utf8', '日本語であそぼ' );
            like $res->content, qr/$str/;
        };
    }
;

done_testing;
