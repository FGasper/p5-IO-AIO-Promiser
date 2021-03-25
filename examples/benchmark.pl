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

my $count = 100;

for (1 .. $count) {
    open my $wfh, '>', "$dir/file-$_";
    print {$wfh} join( q<>, map { rand } 1 .. 100 );
    close $wfh;
}

print "Wrote out files; running benchmark …\n";

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
    },
);
