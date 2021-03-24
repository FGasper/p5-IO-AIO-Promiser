#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use IO::AIO::Promiser;

ok( !__PACKAGE__->can('aio_open'), 'default does NOT export' );

done_testing;
