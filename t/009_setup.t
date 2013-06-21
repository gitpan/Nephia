use strict;
use warnings;
use Test::More;
use Nephia::Setup;
use Capture::Tiny 'capture';
use File::Temp 'tempdir';
use Plack::Test;
use Guard;
use Cwd;

my $pwd = getcwd;

my $dir = tempdir(CLEANUP => 1);
chdir $dir;

my $guard = guard { chdir $pwd };

my $setup = Nephia::Setup->new(
    appname => 'Verdure::Memory',
);

isa_ok $setup, 'Nephia::Setup::Base';
can_ok $setup, 'create';

my($out, $err, @res) = capture {
    $setup->create;
};

is $err, '', 'setup error';
my $expect = join('',(<DATA>));
if ($^O eq 'MSWin32') {
    $expect =~ s/\//\\/g;
}
is $out, $expect, 'setup step';

my $version = Nephia::Setup->get_version;
{
    use Nephia ();
    is $version, $Nephia::VERSION, 'get version';
    no Nephia;
}

undef($guard);

done_testing;
__DATA__
create path Verdure-Memory
create path Verdure-Memory/lib
create path Verdure-Memory/etc
create path Verdure-Memory/etc/conf
create path Verdure-Memory/view
create path Verdure-Memory/root
create path Verdure-Memory/root/static
create path Verdure-Memory/t
spew into file Verdure-Memory/app.psgi
create path Verdure-Memory/lib/Verdure
spew into file Verdure-Memory/lib/Verdure/Memory.pm
spew into file Verdure-Memory/view/index.html
spew into file Verdure-Memory/root/static/style.css
spew into file Verdure-Memory/cpanfile
spew into file Verdure-Memory/t/001_basic.t
spew into file Verdure-Memory/etc/conf/common.pl
spew into file Verdure-Memory/etc/conf/development.pl
spew into file Verdure-Memory/etc/conf/staging.pl
spew into file Verdure-Memory/etc/conf/production.pl
spew into file Verdure-Memory/.gitignore
