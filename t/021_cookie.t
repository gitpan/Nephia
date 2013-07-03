use strict;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;

my $app;

{
    use Nephia;
    path '/set' => sub {
        set_cookie foo => 'bar';
        +{ status => 'ok' };
    };
    path '/get' => sub {
        my $foo = cookie 'foo';
        +{ cookie => $foo };
    };
    $app = __PACKAGE__->run;
}

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET '/set');
    ok $res->is_success;
    is $res->content, encode_json({status => 'ok'});
    is $res->header('Set-Cookie'), 'foo=bar';
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = GET '/get';
    $req->header('Cookie', 'foo=bar');
    my $res = $cb->($req);
    ok $res->is_success;
    is $res->content, encode_json({cookie => 'bar'});
};

done_testing;
