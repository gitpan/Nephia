package Nephia::Plugin::Moz;
use strict;
use warnings;
use utf8;
use JSON;
use Encode;

our @EXPORT = qw/appname/;

sub appname {
    return context('app');
}

sub before_action {
    my ($env, $path_param, @action_chain) = @_;
    context(fun_for => '豊崎愛生');
    my $req = context('req');
    if (my $moz = $req->param('moz')) {
        if ($moz eq 'shock-sheets') {
            return [
                200, 
                ['Content-Type' => 'text/plain; charset=UTF-8'], 
                [Encode::encode_utf8('職質なう')]
            ];
        }
    }
    my $next = shift(@action_chain);
    $next->($env, $path_param, @action_chain);
}

sub process_env {
    my $env = shift;
    $env->{QUERY_STRING} ||= "foo=bar";
    context(moznion => '職');
    return $env;
}

sub process_response {
    my $res = shift;
    my $word = plugin_config('word');
    $res->header('X-Moz' => $word);
    my $moz = context('moznion');
    context(moznion => $moz.'質');
    return $res;
}

sub process_content {
    my $content = shift;
    my $json    = JSON->new->utf8;
    my $moz     = context('moznion');
    my $fun_for = context('fun_for');
    my $data = $json->decode($content);
    my $replace = 'で'.$moz.'カジュアル';
    $data->{message} =~ s/なう/$replace/g;
    $data->{message} = $fun_for.'さんと'.$data->{message};
    return $json->encode($data);
}

1;
