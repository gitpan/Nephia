use strict;
use warnings;
use utf8;
use Nephia::Request;
use Encode;
use Test::More;

my $query = 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2';
my $host  = 'example.com';
my $path  = '/hoge/fuga';
my $path_param = +{id => 'fuga'};

my $req = Nephia::Request->new({
    QUERY_STRING   => $query,
    REQUEST_METHOD => 'GET',
    HTTP_HOST      => $host,
    PATH_INFO      => $path,
});
$req->{path_param} = $path_param;

subtest 'isa' => sub {
    isa_ok $req, 'Nephia::Request';
    isa_ok $req, 'Plack::Request';
};

subtest 'normal' => sub {
    ok Encode::is_utf8($req->param('foo')), 'decoded';
    ok Encode::is_utf8($req->query_parameters->{'foo'}), 'decoded';
    is $req->param('foo'), 'ほげ';
    is_deeply [$req->param('bar')], ['ふが1', 'ふが2'];
};

subtest 'accessor' => sub {
    ok !Encode::is_utf8($req->param_raw('foo')), 'not decoded';
    ok !Encode::is_utf8($req->parameters_raw->{'foo'}), 'not decoded';
};

subtest 'uri' => sub {
    my $uri = $req->uri;
    isa_ok $uri, 'URI';
    is $uri.'', "http://$host$path?$query";

    my $base = $req->base;
    isa_ok $base, 'URI';
    is $base.'', "http://$host/";
};

subtest 'path_param' => sub {
    isa_ok $req->path_param, 'HASH';
    is $req->path_param('id'), 'fuga', 'key specified';
    is $req->path_param('foo'), undef, 'key specified and undefined value';
    is_deeply $req->path_param, +{id => 'fuga'}, 'key not specified';
};

subtest 'nip' => sub {
    isa_ok $req->nip, 'HASH';
    is $req->nip('id'), $req->path_param('id'), 'key specified';
    is $req->nip('foo'), $req->path_param('foo'), 'key specified and undefined value';
    is_deeply $req->nip, $req->path_param, 'key not specified';
};

done_testing;
