use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use JSON;
use utf8;
use Encode qw/encode_utf8/;

use lib qw( ./t/nephia-test_app/lib );
use Nephia::TestApp;

my $app = Plack::Util::load_psgi('t/nephia-test_app/app.psgi');

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;

        subtest "normal request" => sub {
            my $res = $cb->(GET "/json");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            is $res->content_length, 34;
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'Please input a query';
        };

        subtest "request_with_query" => sub {
            my $query = 'おれおれ';
            my $res = $cb->(GET "/json?q=". encode_utf8($query) );
            is $res->code, 200;
            is $res->content_type, 'application/json';
            is $res->content_length, 45;
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'Query OK';
            is $json->{query}, $query;
        };
    }
;

done_testing;
