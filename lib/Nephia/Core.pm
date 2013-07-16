package Nephia::Core;
use strict;
use warnings;

use parent 'Exporter';
use Nephia::Request;
use Nephia::Response;
use Plack::Builder;
use Router::Simple;
use Nephia::View;
use JSON ();
use Encode;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use Module::Load ();

our @EXPORT = qw[ get post put del path req res param path_param nip run config app nephia_plugins base_dir cookie set_cookie ];
our $MAPPER = Router::Simple->new;
our $VIEW;
our $CONFIG = {};
our $CHARSET = Encode::find_encoding('UTF-8');
our $APP_MAP = {};
our $APP_CODE = {};
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
        # setup for submapping one more
        $APP_CODE->{$target_class} ||= {};
        if (!exists $APP_CODE->{$target_class}->{$path}) {
            $APP_CODE->{$target_class}->{$path} = {
                code => $code,
                methods => $methods,
            };
        }

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
                $req->{path_param} = shift;
                local $COOKIE = $req->cookies;
                no strict qw[ refs subs ];
                no warnings qw[ redefine ];
                local *{$caller."::req"} = sub{ $req };
                local *{$caller."::param"} = sub (;$) {
                    my $key = shift;
                    $key ? $req->param($key) : $req->parameters;
                };
                local *{$caller."::path_param"} = sub (;$) { $req->path_param(shift) };
                local *{$caller."::nip"} = sub (;$) { $req->nip(shift) };
                my $res = $code->( $req, $req->path_param );
                my $rtn;
                if ( ref $res eq 'HASH' ) {
                    $rtn = eval { $res->{template} } ?
                        render( $res ) :
                        json_res( $res )
                    ;
                }
                elsif ( blessed $res && $res->isa('Plack::Response') ) {
                    $rtn = $res->finalize;
                }
                else {
                    $rtn = $res;
                }
                if ($COOKIE) {
                    my $res_obj = Nephia::Response->new(@$rtn);
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
    my ( $path, $package, $base_class ) = @_;

    if (!($package =~ s/^\+//g)) {
        $package = join '::', $base_class, $package;
    }

    $APP_MAP->{$package}->{path} = $path;
    if (!$APP_CODE->{$package}) {
        Module::Load::load($package);
        $package->import if $package->can('import');
    }
    else {
         for my $suffix_path (keys %{$APP_CODE->{$package}}) {
            my $app_code = $APP_CODE->{$package}->{$suffix_path};
            _path ($suffix_path, $app_code->{code}, $app_code->{methods}, $package);
        }
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
    my $res = Nephia::Response->new(200);
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
    my $base_dir = base_dir($class);
    $CONFIG = scalar @_ > 1 ? +{ @_ } : $_[0];
    $VIEW = Nephia::View->new( ( $CONFIG->{view} ? %{$CONFIG->{view}} : () ), template_path => File::Spec->catdir($base_dir, 'view') );

    my $root = File::Spec->catfile($base_dir, 'root');
    return builder {
        enable "Static", root => $root, path => qr{^/static/};
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
    my @plugins = @_;

    while (@plugins) {
        my $plugin = shift @plugins;
        $plugin = _normalize_plugin_name($plugin);

        my $opt = $plugins[0] && ref $plugins[0] ? shift @plugins : undef;
        _export_plugin_functions($plugin, $caller, $opt);
    }

};

sub _normalize_plugin_name {
    local $_ = shift;
    /^\+/ ? s/^\+// && $_ : "Nephia::Plugin::$_";
}

sub _export_plugin_functions {
    my ($plugin, $pkg, $opt) = @_;

    Module::Load::load($plugin);

    $plugin->import if $plugin->can('import');
    $plugin->load($pkg, $opt) if $plugin->can('load');
    {
        no strict 'refs';
        no warnings qw/redefine prototype/;
        for my $func ( @{"${plugin}::EXPORT"} ){
            *{"$pkg\::$func"} = $plugin->can($func);
        }
    }
}

sub base_dir {
    my $proto = shift || caller;

    $proto =~ s!::!/!g;
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
