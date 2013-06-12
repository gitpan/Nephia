package Nephia::Core;
use strict;
use warnings;

use Exporter 'import';
use Plack::Request;
use Plack::Response;
use Plack::Builder;
use Router::Simple;
use Nephia::View;
use JSON ();
use FindBin;
use Encode;

our @EXPORT = qw[ get post put del path req res param run config app nephia_plugins ];
our $MAPPER = Router::Simple->new;
our $VIEW;
our $CONFIG = {};
our $CHARSET = 'UTF-8';

sub _path {
    my ( $path, $code, $methods ) = @_;
    my $caller = caller();
    $MAPPER->connect(
        $path, 
        {
            action => sub {
                my $req = Plack::Request->new( shift );
                my $param = shift;
                no strict qw[ refs subs ];
                no warnings qw[ redefine ];
                local *{$caller."::req"} = sub{ $req };
                local *{$caller."::param"} = sub{ $param };
                my $res = $code->( $req, $param );
                if ( ref $res eq 'HASH' ) {
                    return eval { $res->{template} } ? 
                        render( $res ) : 
                        json_res( $res )
                    ;
                }
                elsif ( ref $res eq 'Plack::Response' ) {
                    return $res->finalize;
                }
                else {
                    return $res;
                }
            },
        },
        $methods ? { method => $methods } : undef,
    );
}

sub get ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['GET'] );
}

sub post ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['POST'] );
}

sub put ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['PUT'] );
}

sub del ($&) {
    my ( $path, $code ) = @_;
    _path( $path, $code, ['DELETE'] );
}

sub path ($@) {
    my ( $path, $code, $methods ) = @_;
    _path( $path, $code, $methods );
}

sub res (&) {
    my $code = shift;
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    {
        no strict qw[ refs subs ];
        no warnings qw[ redefine ];
        my $caller = caller();
        map { 
            my $method = $_;
            *{$caller.'::'.$method} = sub (@) { 
                $res->$method( @_ );
                return;
            };
        } qw[ 
            status headers body header
            content_type content_length
            content_encoding redirect cookies
        ];
        my @rtn = ( $code->() );
        if ( @rtn ) {
            $rtn[1] ||= [];
            $rtn[2] ||= [];
            $res = [@rtn];
        }
    }
    return $res;
}

sub run {
    my $class = shift;
    $CONFIG = scalar @_ > 1 ? +{ @_ } : $_[0];
    $VIEW = Nephia::View->new( $CONFIG->{view} ? %{$CONFIG->{view}} : () );
    return builder { 
        enable "ContentLength";
        enable "Static", root => "$FindBin::Bin/root/", path => qr{^/static/};
        $class->app;
    };
}

sub app {
    my $class = shift;
    return sub {
        my $env = shift;
        if ( my $p = $MAPPER->match($env) ) {
            $p->{action}->($env, $p);
        }
        else {
            [404, [], ['Not Found']];
        }
    };
}

sub json_res {
    my $res = shift;
    my $body = JSON->new->utf8->encode( $res );
    return [ 200, 
        [ 
            'Content-type'           => 'application/json',
            'X-Content-Type-Options' => 'nosniff',  ### For IE 9 or later. See http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-1297
            'X-Frame-Options'        => 'DENY',     ### Suppress loading web-page into iframe. See http://blog.mozilla.org/security/2010/09/08/x-frame-options/
            'Cache-Control'          => 'private',  ### no public cache
        ],
        [ $body ]
    ];
}

sub render {
    my $res = shift;
    my $charset = delete $res->{charset} || $CHARSET;
    my $body = $VIEW->render( $res->{template}, $res );
    return [ 200,
        [ 'Content-type' => "text/html; charset=$charset" ],
        [ Encode::encode( $charset, $body ) ]
    ];
}

sub config (@) {
    if ( scalar @_ > 0 ) {
        $CONFIG = 
            scalar @_ > 1 ? { @_ } : 
            ref $_[0] eq 'HASH' ? $_[0] :
            do( $_[0] )
        ;
    }
    return $CONFIG;
};

sub nephia_plugins (@) {
    my $caller = caller();
    for my $plugin ( map {'Nephia::Plugin::'.$_} @_ ) {
        _export_plugin_functions($plugin, $caller);
    }
};

sub _export_plugin_functions {
    my ($plugin, $caller) = @_;
    my $plugin_path = File::Spec->catfile(split('::', $plugin)).'.pm';
    require $plugin_path;
    {
        no strict 'refs';
        my @funcs = grep { $_ =~ /^[a-z]/ && $_ ne 'import' } keys %{$plugin.'::'};
        *{$caller.'::'.$_} = *{$plugin.'::'.$_} for @funcs;
    }
}

1;
