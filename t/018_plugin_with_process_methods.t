use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;
use utf8;
use Encode;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestPluginApp2nd;
use t::Util;

test_psgi
    app => Nephia::TestPluginApp2nd->run( test_config ),
    client => sub {
        my $cb = shift;
        subtest "normal" => sub {
            my $res = $cb->(GET "/");
            is $res->code, 200, 'response ok';
            is $res->header('X-Moz'), 'kieeeee', 'process_response';
            my $json = JSON->new->utf8->decode($res->content);
            is $json->{params}, 'bar', 'process_request';
            is $json->{message}, 'fii職質', 'process_content';
            is $json->{appname}, 'Nephia::TestPluginApp2nd';
        };
    }
;

done_testing;
