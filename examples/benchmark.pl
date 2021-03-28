#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark;

use File::Temp;

use IO::AIO ();
use AnyEvent::AIO ();

use IO::AIO::Promiser ();

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $count = 400;

my @additional_benchmarks;
if (eval { require fs::Promises }) {
    print "fs::Promises is available; including it in benchmarks …\n";

    push @additional_benchmarks, fs_promises => sub {
        my @p = map { fs::Promises::slurp("$dir/file-$_", 0, 0) } 1 .. $count;

        IO::AIO::flush;
    },
}

print "Writing files in $dir …\n";

for (1 .. $count) {
    open my $wfh, '>', "$dir/file-$_";
    print {$wfh} join( q<>, map { rand } 1 .. 100 );
    close $wfh;
}

print "Wrote out files; running benchmarks …\n";

Benchmark::cmpthese(
    1000,
    {
        plain => sub {
            for (1 .. $count) {
                open my $wfh, '<', "$dir/file-$_";
                my $content = do { local $/; <$wfh> };
            }
        },

        io_aio => sub {
            my @content = (undef) x $count;

            for (1 .. $count) {
                my $i = $_;
                IO::AIO::aio_slurp("$dir/file-$_", 0, 0, $content[$i], sub { warn "open failed: $!" if !shift } );
            }

            IO::AIO::flush;
        },

        io_aio_promiser => sub {
            my @p = map { IO::AIO::Promiser::slurp("$dir/file-$_", 0, 0) } 1 .. $count;

            IO::AIO::flush;
        },

        @additional_benchmarks,
    },
);
