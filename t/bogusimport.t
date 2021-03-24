#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

my $import_err;

BEGIN {
    eval "use IO::AIO::Promiser ':bogus'";
    $import_err = $@;
}

like($import_err, qr<bogus>, 'fail as expected w/ bad import tag' );

done_testing;
