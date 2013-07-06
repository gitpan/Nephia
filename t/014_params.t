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
            my $res = $cb->(GET "/with/ytnobody");
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'ytnobodyと踊った';
        };

        subtest "request_with_query" => sub {
            my $query = 'おっとっと';
            my $res = $cb->(GET "/with/ytnobody?action=". encode_utf8($query) );
            is $res->code, 200;
            is $res->content_type, 'application/json';
            my $json = JSON->new->utf8->decode( $res->content );
            is $json->{message}, 'ytnobodyとおっとっと';
        };
    }
;

done_testing;
