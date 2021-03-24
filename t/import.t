#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use IO::AIO::Promiser ':all';

can_ok( __PACKAGE__, 'aio_open' );

done_testing;
