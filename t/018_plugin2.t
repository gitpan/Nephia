use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;
use utf8;
use Encode;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestPluginApp;
use t::Util;

is $Nephia::BARK, 'FOO', 'import check';

test_psgi
    app => Nephia::TestPluginApp->run( test_config ),
    client => sub {
        my $cb = shift;
        subtest "bark" => sub {
            my $res = $cb->(GET "/bark");
            is $res->code, 200;
            is $res->content, 'Bark!';
        };

        subtest "wei" => sub {
            my $res = $cb->(GET "/wei");
            is $res->code, 200;
            is $res->content, encode_utf8('うぇーい');
        };
    }
;

done_testing;
