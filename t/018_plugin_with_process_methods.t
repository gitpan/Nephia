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

binmode STDOUT,'utf8';

test_psgi
    app => Nephia::TestPluginApp2nd->run( test_config ),
    client => sub {
        my $cb = shift;
        subtest "normal" => sub {
            my $res = $cb->(GET "/");
            is $res->code, 200, 'response ok';
            is $res->header('X-Moz'), 'kieeeee', 'process_response';
            my $json = JSON->new->utf8->decode($res->content);
            is $json->{params}, 'bar', 'process_env';
            is $json->{message}, '豊崎愛生さんと八王子で職質カジュアル', 'process_content';
            is $json->{appname}, 'Nephia::TestPluginApp2nd', 'context("app") is Nephia::TestPluginApp2nd';
        };

        subtest "before_action" => sub {
            my $res = $cb->(GET "/?moz=shock-sheets");
            is $res->code, 200, 'response ok';
            is $res->header('X-Moz'), undef, 'skip process_response';
            is $res->content, Encode::encode_utf8('職質なう'), 'content is "職質なう"';
        };
    }
;

done_testing;
