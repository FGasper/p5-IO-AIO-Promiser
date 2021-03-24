#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;

use File::Temp;

use IO::AIO ();
use AnyEvent::AIO ();

use IO::AIO::Promiser ();

my $dir = File::Temp::tempdir( CLEANUP => 1 );

print "dir: $dir\n";

print "Press any key to continue.\n";
<>;

my $count = 10000;

Benchmark::cmpthese(
    10,
    {
        plain => sub {
            mkdir "$dir/mkdir-$_" for 1 .. $count;
        },

        io_aio => sub {
            my $did = 0;

            for (1 .. $count) {
                IO::AIO::aio_mkdir("$dir/ioaio-$_", 0, sub { $did++ } );
            }

            IO::AIO::flush;
        },

        io_aio_promiser => sub {
            my @p = map { IO::AIO::Promiser::mkdir("$dir/ioaiop-$_", 0) } 1 .. $count;
            IO::AIO::flush;
        },
    },
);
