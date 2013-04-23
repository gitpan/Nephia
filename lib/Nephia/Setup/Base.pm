package Nephia::Setup::Base;
use strict;
use warnings;
use File::Spec;
use Path::Class;
use Cwd;
use Carp;
use Class::Accessor::Lite (
    new => 0,
    rw => [qw( appname approot pmpath )],
);

sub new {
    my ( $class, %opts ) = @_;

    my $appname = $opts{appname}; $appname =~ s/::/-/g;
    $opts{approot} = dir( File::Spec->catfile( '.', $appname ) );

    $opts{pmpath} = file( File::Spec->catfile( $opts{approot}->stringify, 'lib', split(/::/, $opts{appname}. '.pm') ) );

    return bless { %opts }, $class;
}

sub create {
    my $self = shift;

    $self->approot->mkpath( 1, 0755 );
    map {
        $self->approot->subdir($_)->mkpath( 1, 0755 );
    } qw( lib etc etc/conf view root root/static t );

    $self->psgi_file;
    $self->app_class_file;
    $self->index_template_file;
    $self->css_file;
    $self->makefile;
    $self->basic_test_file;
    $self->config_file;
}

sub nephia_version {
    my $self = shift;
    return $self->{nephia_version} ? $self->{nephia_version} : do {
        require Nephia;
        $Nephia::VERSION;
    };
}

sub templates {
    my $self = shift;
    unless ( $self->{templates} ) {
        my @data = <DATA>;
        $self->{templates} = +{ 
            map { 
                my ($key, $template) = split("---", $_, 2); 
                $key =~ s/(\s|\r|\n)//g;
                $template =~ s/^\n//;
                ($key, $template);
            } 
            split("===", join('', @data) )
        };
    }
    return $self->{templates} ;
}

sub psgi_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{psgi_file};
    $body =~ s[\$appname][$appname]g;
    $self->approot->file('app.psgi')->spew( $body );
}

sub app_class_file {
    my $self = shift;
    my $approot = $self->approot;
    my $appname = $self->appname;
    my $body = $self->templates->{app_class_file};
    $body =~ s[\$approot][$approot]g;
    $body =~ s[\$appname][$appname]g;
    $body =~ s[:::][=]g;
    $self->pmpath->dir->mkpath( 1, 0755 );
    $self->pmpath->spew( $body );
}

sub index_template_file {
    my $self = shift;
    my $body = $self->templates->{index_template_file};
    $self->approot->file('view', 'index.tx')->spew( $body );
}

sub css_file {
    my $self = shift;
    my $body = $self->templates->{css_file};
    $self->approot->file('root', 'static', 'style.css')->spew( $body );
}

sub makefile {
    my $self = shift;
    my $appname = $self->appname;
    $appname =~ s[::][-]g;
    my $pmpath = $self->pmpath;
    $pmpath =~ s[$appname][.];
    my $version = $self->nephia_version;
    my $body = $self->templates->{makefile};
    $body =~ s[\$appname][$appname]g;
    $body =~ s[\$pmpath][$pmpath]g;
    $body =~ s[\$NEPHIA_VERSION][$version]g;
    $self->approot->file('Makefile.PL')->spew( $body );
}

sub basic_test_file {
    my $self = shift;
    my $appname = $self->appname;
    my $body = $self->templates->{basic_test_file};
    $body =~ s[\$appname][$appname]g;
    $self->approot->file('t','001_basic.t')->spew( $body );
}

sub config_file {
    my $self = shift;
    my $appname = $self->appname;
    $appname =~ s[::][-]g;
    my $common = $self->templates->{common_conf};
    $common =~ s[\$appname][$appname]g;
    my $common_conf = $self->approot->file('etc','conf','common.pl');
    my $common_conf_path = $common_conf->stringify;
    $common_conf_path =~ s[^$appname][.];
    $common_conf->spew( $common );
    for my $envname (qw( development staging production )) {
        my $body = $self->templates->{conf_file};
        $body =~ s[\$common_conf_path][$common_conf_path]g;
        $body =~ s[\$envname][$envname]g;
        $self->approot->file('etc','conf',$envname.'.pl')->spew( $body );
    }
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
        template => 'index.tx',
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
__END__

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
  <title><: $title :> - powerd by Nephia</title>
</head>
<body>
  <div class="title">
    <h1><: $title :></h1>
    <p><: $envname :></p>
  </div>

  <div class="content">
    <h2>Hello, Nephia world!</h2>
    <p>Nephia is a mini web-application framework.</p>
    <pre>
    ### <: $apppath :>
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
  </div>

  <div class="content">
    And more...
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
    background: #45484d; /* Old browsers */
    background: -moz-linear-gradient(top,  #45484d 0%, #000000 100%); /* FF3.6+ */
    background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#45484d), color-stop(100%,#000000)); /* Chrome,Safari4+ */
    background: -webkit-linear-gradient(top,  #45484d 0%,#000000 100%); /* Chrome10+,Safari5.1+ */
    background: -o-linear-gradient(top,  #45484d 0%,#000000 100%); /* Opera 11.10+ */
    background: -ms-linear-gradient(top,  #45484d 0%,#000000 100%); /* IE10+ */
    background: linear-gradient(to bottom,  #45484d 0%,#000000 100%); /* W3C */
    filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#45484d', endColorstr='#000000',GradientType=0 ); /* IE6-9 */
    color: #eed;
    text-shadow: 3px 3px 3px #000;
}

div.title {
    width: 80%;
    margin: auto;
    margin-top: 20px;
    background: #ff5db1; /* Old browsers */
    background: -moz-linear-gradient(top,  #ff5db1 0%, #ef017c 100%); /* FF3.6+ */
    background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#ff5db1), color-stop(100%,#ef017c)); /* Chrome,Safari4+ */
    background: -webkit-linear-gradient(top,  #ff5db1 0%,#ef017c 100%); /* Chrome10+,Safari5.1+ */
    background: -o-linear-gradient(top,  #ff5db1 0%,#ef017c 100%); /* Opera 11.10+ */
    background: -ms-linear-gradient(top,  #ff5db1 0%,#ef017c 100%); /* IE10+ */
    background: linear-gradient(to bottom,  #ff5db1 0%,#ef017c 100%); /* W3C */
    filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#ff5db1', endColorstr='#ef017c',GradientType=0 ); /* IE6-9 */
    padding: 10px 30px;
    border-radius: 20px;
    box-shadow: 7px 10px 30px #000;
    color: #eed;
    text-shadow: 3px 3px 3px #000;
}

div.content {
    background-color: #666;
    width: 80%;
    margin: 20px auto;
    padding: 10px 30px;
    border-radius: 20px;
    box-shadow: 7px 10px 30px #000;
}

pre,ul {
    line-height: 1.2em;
    padding-top: 10px;
    padding-bottom: 10px;
    background-color: #ccc;
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

makefile
---
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => '$appname',
    AUTHOR           => q{clever guy <who@example.com>},
    VERSION_FROM     => '$pmpath',
    ABSTRACT_FROM    => '$pmpath',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Nephia' => '$NEPHIA_VERSION',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => '$appname-*' },
);


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
+{
    appname => '$appname',
};
===

conf_file
---
### environment specific config
use File::Spec;
use File::Basename 'dirname';
my $basedir = File::Spec->rel2abs(
    File::Spec->catdir( dirname(__FILE__), '..', '..' )
);
+{
    %{ do(File::Spec->catfile($basedir, 'etc', 'conf', 'common.pl')) },
    envname => '$envname',
};
