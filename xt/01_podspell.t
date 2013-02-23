use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
ytnobody
ytnobody@gmail.com
Nephia
WAF
DSL
JSON
Kolon
Xslate
customisable
javascripts
req
validator
UTF
nephia
psgi
utf
del
param
plack
appname
conf
dirname
envname
gz
powerd
px

