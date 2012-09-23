package MyApp::Root;

use strict;
use warnings;
use Nephia;

path '/' => sub {
    { title => 'Nephia Sample',
      template => 'hoge.tx',
    };
};

1;
