#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use Cwd ();
use FindBin;
use File::Temp  qw/tempdir/;
use File::Path  qw/mkpath/;
use File::pushd qw/pushd/;
use File::Spec;
use Plack::Test;
use HTTP::Request::Common;

use Test::More;

use constant NEPHIA_APP    => 'nephia_app';
use constant BASE_DIR_FUNC => '_base_dir';
use constant LIB           => File::Spec->catfile("$FindBin::Bin", '..', 'lib');
use constant TEST_SCRIPT   => 'test_run.pl';

my $guard        = pushd(tempdir(CLEANUP => 1));
my $current_dir  = Cwd::getcwd();
my $nephia_setup = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'nephia-setup');

system $^X, '-I' . LIB, $nephia_setup, NEPHIA_APP;
chdir NEPHIA_APP;

subtest 'top level' => sub {
    {
        open my $fh, '>', TEST_SCRIPT;
        print $fh <<'EOS';
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
EOS
        print $fh 'use ' . NEPHIA_APP . ";\n";
        print $fh NEPHIA_APP . '::' . BASE_DIR_FUNC . '();';
    };

    {
        open my $fh, '>>', File::Spec->catfile('lib', NEPHIA_APP . '.pm');
        print $fh 'sub ' . BASE_DIR_FUNC . ' { print base_dir; }';
    };

    my ($got) = capture { system $^X, '-I' . LIB, TEST_SCRIPT };
    is $got, File::Spec->catfile($current_dir, NEPHIA_APP), 'should be got app root rightly';
};

subtest 'child' => sub {
    my $child_module = 'child';
    {
        open my $fh, '>', TEST_SCRIPT;
        print $fh <<'EOS';
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
EOS
        print $fh 'use ' . NEPHIA_APP . "::$child_module;\n";
        print $fh NEPHIA_APP . "::$child_module" . '::' . BASE_DIR_FUNC . '();';
    };

    mkpath(File::Spec->catfile('lib', NEPHIA_APP));
    {
        open my $fh, '>', File::Spec->catfile('lib', NEPHIA_APP,  "$child_module.pm");
        print $fh "package " . NEPHIA_APP . "::$child_module;\n";
        print $fh <<'EOS';
use strict;
use warnings;
use Nephia;
EOS
        print $fh 'sub ' . BASE_DIR_FUNC . " { print base_dir; }\n";
        print $fh '1;'
    };

    my ($got) = capture { system $^X, '-I' . LIB, TEST_SCRIPT };
    is $got, File::Spec->catfile($current_dir, NEPHIA_APP), 'should be got app root rightly';
};

subtest 'psgi' => sub {
    my $app = eval {
        use Nephia;
        path '/' => sub { res {(200, [], [base_dir] )} };
        __PACKAGE__->run;
    };
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        ok $res->is_success, 'request OK';
        is $res->content, File::Spec->catfile($current_dir, NEPHIA_APP), 'should be got app root rightly';
    };
};

done_testing;
