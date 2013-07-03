package Nephia::Core;
use strict;
use warnings;

use Exporter 'import';
use Nephia::Request;
use Plack::Response;
use Plack::Builder;
use Router::Simple;
use Nephia::View;
use Nephia::ClassLoader;
use JSON ();
use FindBin;
use Encode;
use Carp qw/croak/;

our @EXPORT = qw[ get post put del path req res param run config app nephia_plugins base_dir cookie set_cookie ];
our $MAPPER = Router::Simple->new;
our $VIEW;
our $CONFIG = {};
our $CHARSET = 'UTF-8';
our $APP_MAP = {};
our $APP_ROOT;
our $COOKIE;

sub _path {
    my ( $path, $code, $methods, $target_class ) = @_;
    my $caller = caller();

    if (
        $target_class
        && exists $APP_MAP->{$target_class}
        && $APP_MAP->{$target_class}->{path}
    ) {
        $path =~ s!^/!!g;
        my @paths = ($APP_MAP->{$target_class}->{path});
        push @paths, $path if length($path) > 0;
        $path = join '/', @paths;
    }

    $MAPPER->connect(
        $path,
        {
            action => sub {
                my $req = Nephia::Request->new( shift );
                local $COOKIE = $req->cookies;
                my $param = shift;
                no strict qw[ refs subs ];
                no warnings qw[ redefine ];
                local *{$caller."::req"} = sub{ $req };
                local *{$caller."::param"} = sub{ $param };
                my $res = $code->( $req, $param );
                my $rtn;
                if ( ref $res eq 'HASH' ) {
                    $rtn = eval { $res->{template} } ?
                        render( $res ) :
                        json_res( $res )
                    ;
                }
                elsif ( ref $res eq 'Plack::Response' ) {
                    $rtn = $res->finalize;
                }
                else {
                    $rtn = $res;
                }
                if ($COOKIE) {
                    my $res_obj = Plack::Response->new(@$rtn);
                    for my $key (keys %$COOKIE) {
                        $res_obj->cookies->{$key} = $COOKIE->{$key};
                    }
                    $rtn = $res_obj->finalize;
                }
                return $rtn;
            },
        },
        $methods ? { method => $methods } : undef,
    );

}

sub _submap {
    my ( $path, $code, $base_class ) = @_;

    $code =~ s/^\+/$base_class\::/g;

    eval {
        $APP_MAP->{$code}->{path} = $path;
        Nephia::ClassLoader->load($code);
        import $code;
    };
    if ($@) {
        my $e = $@;
        chomp $e;
        $e =~ s/\ at\ .*$//g;
        croak $e;
    }
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
    my $caller = caller();
    if ( ref $code eq "CODE" ) {
        _path( $path, $code, $methods, $caller );
    }
    else {
        _submap( $path, $code, $caller );
    }
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

{
    my $_json;
    sub _json { $_json ||= JSON->new->utf8 }
}
sub json_res {
    my $res = shift;
    my $body = _json->encode( $res );
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
        $plugin->import if *{$plugin."::import"}{CODE};
        my @funcs = grep { $_ =~ /^[a-z]/ && $_ ne 'import' } keys %{$plugin.'::'};
        *{$caller.'::'.$_} = *{$plugin.'::'.$_} for @funcs;
    }
}

sub base_dir {
    my ($proto) = caller();

    my $base_dir;
    if (my $libpath = $INC{"$proto.pm"}) {
        $libpath =~ s!\\!/!g; # for win32
        $libpath =~ s!(?:blib/)?lib/+$proto\.pm$!!;
        $base_dir = File::Spec->rel2abs($libpath || '.');
    } else {
        $base_dir = File::Spec->rel2abs('.');
    }

    no warnings 'redefine';
    *Nephia::Core::base_dir = sub {
        return $base_dir;
    };

    return $base_dir;
}

sub set_cookie ($$){
    my ($key, $val) = @_;
    $COOKIE->{$key} = $val;
}

sub cookie ($) {
    my $key = shift;
    $COOKIE->{$key};
}

1;
