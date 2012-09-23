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

        subtest "normal request" => sub {
            my $res = $cb->(GET "/json");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            is $res->content_length, 34;
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'Please input a query';
        };

        subtest "request_with_query" => sub {
            my $query = Encode::encode( 'utf8', 'おれおれ' );
            my $res = $cb->(GET "/json?q=$query" );
            is $res->code, 200;
            is $res->content_type, 'application/json';
            is $res->content_length, 57;
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'Query OK';
            is $json->{query}, $query;
        };
    }
;

done_testing;
