use warnings;
use Test::More;
use File::Spec;
use File::Basename 'dirname';
use Capture::Tiny 'capture';

subtest 'origin' => sub {
    use Nephia;
    use Nephia::DSLModifier;
    my $code = origin 'render';
    is $code, *{'Nephia::Core::render'}{CODE};
};

subtest 'around' => sub {
    use Nephia;
    use Nephia::DSLModifier;
    my $code = origin 'base_dir';
    is(File::Spec->catdir(base_dir, 't'), File::Spec->rel2abs(dirname(__FILE__)), 'plain');
    around base_dir => sub {
        my $orig = pop;
        my $res = $orig->(@_);
        return "dir=$res";
    };
    is(base_dir, "dir=". $code->(), 'modified');
};

subtest 'before and after' => sub {
    use Nephia;
    use Nephia::DSLModifier;
    my $code = origin 'base_dir';
    before base_dir => sub { print "foo" };
    after base_dir => sub { print "bar" };
    my ($out, $err, $res) = capture { base_dir };
    is $out, "foobar", 'output before base_dir';
    is $res, $code->(), 'same response';
};

done_testing;
