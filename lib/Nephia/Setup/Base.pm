package Nephia::Setup::Base;
use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';
use Cwd;
use Carp;
use Class::Accessor::Lite (
    new => 0,
    rw => [qw( appname approot pmpath templates meta_template )],
);
use Nephia::MetaTemplate;

sub new {
    my ( $class, %opts ) = @_;

    my $appname = $opts{appname};
    $appname =~ s/::/-/g;
    $opts{approot} = File::Spec->catdir('.', $appname);
    $opts{pmpath} = File::Spec->catfile( $opts{approot}, 'lib', split(/::/, $opts{appname}. '.pm') );
    $opts{meta_template} = Nephia::MetaTemplate->new;

    return bless { %opts,
        required_modules => {
            'Nephia'        => '0',
            'Config::Micro' => '0.02',
        },
        additional_methods => {},
    }, $class;
}

sub _parse_template_data {
    my ($self, @data) = @_;
    $self->templates( +{
        map {
            my ($key, $template) = split("---", $_, 2);
            $key =~ s/(\s|\r|\n)//g;
            $template =~ s/^\n//;
            ($key, $template);
        }
        grep { $_ =~ /---/ }
        split("===", join('', @data) )
    } );
}

sub _set_required_modules {
    my ($self, $required_modules) = @_;

    for my $module (keys %{$required_modules}) {
        my $version = $required_modules->{$module};
        if (defined $self->{required_modules}->{$module}) {
            my $defined_version = $self->{required_modules}->{$module};
            $self->{required_modules}->{$module} = $defined_version > $version ? $defined_version : $version;
        } else {
            $self->{required_modules}->{$module} = $version;
        }
    }
}

sub create {
    my $self = shift;

    if (-d $self->approot) {
        croak "Cannot mkdir '" . $self->approot . "': Directory exists";
    }

    $self->mkpath($self->approot);
    map {
        my @path = split '/', $_;
        $self->mkpath($self->approot, @path);
    } qw( lib etc etc/conf view root root/static t );

    $self->changes_file;
    $self->psgi_file;
    $self->app_class_file;
    $self->index_template_file;
    $self->css_file;
    $self->cpanfile;
    $self->basic_test_file;
    $self->config_file;
    $self->gitignore_file;

    for my $method (keys %{$self->{additional_methods}}) {
        $self->$method if $self->can($method);
    }
}

sub spew {
    my ($self, $file, $body) = @_;
    print "spew into file $file\n";
    open my $fh, '>', $file or croak "could not spew into $file: $!";
    print $fh $body;
    close $fh;
}

sub spew_as_template {
    my ($self, $file, $body) = @_;
    my $template_body = $self->meta_template->process($body);
    $self->spew($file, $template_body);
}

sub mkpath {
    my ($self, @part) = @_;
    my $path = File::Spec->catdir(@part);
    unless (-d $path) {
        print "create path $path\n";
        mkdir $path, 0755 or croak "could not create path $path: $!";
    }
}

sub dir {
    my ($self, @part) = @_;
    my $path = File::Spec->catfile(@part);
    dirname($path);
}

sub psgi_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{psgi_file};
    $body =~ s[\$appname][$appname]g;
    my $file = File::Spec->catfile($self->approot, 'app.psgi');
    $self->spew($file, $body);
}

sub app_class_file {
    my $self = shift;
    my $approot = $self->approot;
    my $appname = $self->appname;
    my $body = $self->templates->{app_class_file};
    $body =~ s[\$approot][$approot]g;
    $body =~ s[\$appname][$appname]g;
    $body =~ s[:::][=]g;
    my $dir = $self->dir($self->pmpath);
    $self->mkpath($dir);
    $self->spew($self->pmpath, $body);
}

sub index_template_file {
    my $self = shift;
    my $body = $self->templates->{index_template_file};
    my $file = File::Spec->catfile($self->approot, qw/view index.html/);
    $self->spew_as_template($file, $body);
}

sub css_file {
    my $self = shift;
    my $body = $self->templates->{css_file};
    my $file = File::Spec->catfile($self->approot, qw/root static style.css/);
    $self->spew($file, $body);
}

sub changes_file {
    my $self = shift;
    my $body = $self->templates->{Changes};
    my $appname = $self->appname;
    $body =~ s[\$appname][$appname]g;
    my $file = File::Spec->catfile($self->approot, qw/Changes/);
    $self->spew($file, $body);
}

sub cpanfile {
    my $self = shift;

    my $required_modules = join "\n", map {
        qq{requires '$_' => '$self->{required_modules}->{$_}';}
    } sort {
        ($b =~ /Nephia/) <=> ($a =~ /Nephia/) || $a cmp $b
    } keys %{$self->{required_modules}};

    my $appname = $self->appname;
    $appname =~ s[::][-]g;
    my $pmpath = $self->pmpath;
    $pmpath =~ s[$appname][.];
    my $body = $self->templates->{cpanfile};
    $body =~ s[\$required_modules][$required_modules]g;
    my $file = File::Spec->catfile($self->approot, 'cpanfile');
    $self->spew($file, $body);
}

sub basic_test_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{basic_test_file};
    $body =~ s[\$appname][$appname]g;
    my $file = File::Spec->catfile($self->approot, qw/t 001_basic.t/);
    $self->spew($file, $body);
}

sub config_file {
    my $self = shift;
    my $appname = $self->appname;
    $appname =~ s[::][-]g;
    my $common = $self->templates->{common_conf};
    $common =~ s[\$appname][$appname]g;
    my $common_conf_path = File::Spec->catfile($self->approot, 'etc','conf','common.pl');
    $self->spew($common_conf_path, $common);
    for my $envname (qw( development staging production )) {
        my $body = $self->templates->{conf_file};
        $body =~ s[\$common_conf_path][$common_conf_path]g;
        $body =~ s[\$envname][$envname]g;
        my $file = File::Spec->catfile($self->approot, 'etc', 'conf', $envname.'.pl');
        $self->spew($file, $body);
    }
}

sub gitignore_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{gitignore_file};
    $body =~ s[\$appname][$appname]g;
    my $file = File::Spec->catfile($self->approot, '.gitignore');
    $self->spew($file, $body);
}

1;

__DATA__

psgi_file
---
use strict;
use warnings;
use FindBin;
use Config::Micro;
use File::Spec;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
use $appname;
my $config = require( Config::Micro->file( dir => File::Spec->catdir('etc','conf') ) );
$appname->run( $config );
===

app_class_file
---
package $appname;
use strict;
use warnings;
use Nephia;

our $VERSION = 0.01;

path '/' => sub {
    my $req = shift;
    return {
        template => 'index.html',
        title    => config->{appname},
        envname  => config->{envname},
        apppath  => 'lib/' . __PACKAGE__ .'.pm',
    };
};

path '/data' => sub {
    my $req = shift;
    return { # return JSON unless {template}
        #template => 'index.tx',
        title    => config->{appname},
        envname  => config->{envname},
    };
};

1;

:::head1 NAME

$appname - Web Application

:::head1 SYNOPSIS

  $ plackup

:::head1 DESCRIPTION

$appname is web application based Nephia.

:::head1 AUTHOR

clever guy

:::head1 SEE ALSO

Nephia

:::head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

:::cut

===

index_template_file
---
<html>
<head>
  <link rel="stylesheet" href="/static/style.css" />
  <link rel="shortcut icon" href="/static/favicon.ico" />
  <title>[= title =] - powerd by Nephia</title>
</head>
<body>
  <div class="title">
    <span class="title-label">[= title =]</span>
    <span class="envname">[= envname =]</span>
  </div>

  <div class="content">
    <h2>Hello, Nephia world!</h2>
    <p>Nephia is a mini web-application framework.</p>
    <pre>
    ### [= apppath =]
    use Nephia;

    # <a href="/data">JSON responce sample</a>
    path '/data' => sub {
        my $req = shift;

        return { # responce-value as JSON unless exists {template}
            #template => 'index.tx',
            title    => config->{appname},
            envname  => config->{envname},
        };
    };
    </pre>
    <h2>See also</h2>
    <ul>
      <li><a href="https://metacpan.org/module/Nephia">Read the documentation</a></li>
    </ul>
  </div>

  <address class="generated-by">Generated by Nephia</address>
</body>
</html>

===

css_file
---
body {
    text-align: center;
    background: #f7f7f7;
    color: #666;
    padding: 0px;
    margin: 0px;
    font-family: 'Hiragino Kaku Gothic ProN', Meiryo, 'MS PGothic', Sans-serif;
}

h1,h2,h3,h4,h5 {
    color: #333;
    border-left: 10px solid #36c;
    font-weight: 100;
    padding: 4px 7px;
}

a {
    color: #36c;
}

div.title {
    text-align: justify;
    width: 100%;
    margin: 0px;
    padding: 0px;
    background-color: #36c;
    border-bottom: 2px solid #fff;
    color: #f7f7f7;
}

span.title-label {
    font-weight: 100;
    font-size: 1.4em;
    margin: 0px 10px;
}

span.envname {
    font-size: 0.8em;
}

div.content {
    text-align: justify;
    background-color: #fff;
    width: 80%;
    margin: 20px auto;
    padding: 10px 30px;
    border-radius: 4px;
    border: 2px solid #eee;
}

pre {
    line-height: 1.2em;
    padding: 10px 2px;
    background-color: #f5f5f5;
    border-radius: 4px;
    border: 1px solid #eee;
    text-shadow:none;
    color: #111;
}

address.generated-by {
    width: 80%;
    padding: 0px 30px;
    margin: auto;
    margin-top: 20px;
    text-align: right;
    font-style: normal;
}

===

cpanfile
---
$required_modules

on test => sub {
    requires 'Test::More', '0.98';
};


===

basic_test_file
---
use strict;
use warnings;
use Test::More;
BEGIN {
    use_ok( '$appname' );
}
done_testing;
===

common_conf
---
### common config
use utf8;
+{
    appname => '$appname',
};
===

conf_file
---
### environment specific config
use utf8;
use File::Spec;
use File::Basename 'dirname';
my $basedir = File::Spec->rel2abs(
    File::Spec->catdir( dirname(__FILE__), '..', '..' )
);
+{
    %{ do(File::Spec->catfile($basedir, 'etc', 'conf', 'common.pl')) },
    envname => '$envname',
};
===

gitignore_file
---
cover_db
META.yml
Makefile
blib
pm_to_blib
MANIFEST
Makefile.old
nytprof.out
MANIFEST.bak
*.sw[po]
/$appname-*
/.build
/_build_params
/Build
/_build
!Build/
!META.json
!LICENSE
MYMETA.*
inc
===

Changes
---
{{$NEXT}}
        - original version
===
