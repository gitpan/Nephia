use strict;
use warnings;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/extlib/lib/perl5");
use Nephia::ParentApp;
Nephia::ParentApp->run();
