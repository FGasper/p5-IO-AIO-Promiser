#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Socket;
use Fcntl;
use Errno;
use Config;

use IO::AIO;
use IO::AIO::Promiser;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

socket my $s, Socket::AF_INET, Socket::SOCK_STREAM, 0;

my @got;

IO::AIO::Promiser::wd("$dir/ha/ha")->catch(
    sub { @got = ('wd', 0 + shift) },
);

IO::AIO::flush;

is_deeply( \@got, [ 'wd', Errno::ENOENT ], 'wd fail' );

IO::AIO::Promiser::realpath("$dir/ha/ha")->catch(
    sub { @got = ('realpath', 0 + shift) },
);

IO::AIO::flush;

is_deeply( \@got, [ 'realpath', Errno::ENOENT ], 'realpath fail' );

IO::AIO::Promiser::open("$dir/ha/ha", Fcntl::O_CREAT, 0)->catch(
    sub { @got = 0 + shift },
);

IO::AIO::flush;

is_deeply( \@got, [ Errno::ENOENT ], 'open fail' );

IO::AIO::Promiser::seek($s, 0, 0)->catch(
    sub { @got = ('seek', 0 + shift) },
);

IO::AIO::flush;

is_deeply( \@got, [ 'seek', Errno::ESPIPE ], 'seek fail' );

my $data = q<>;
IO::AIO::Promiser::read($s, 0, 5, $data, 0)->catch(
    sub { @got = ('read', 0 + shift) },
);

IO::AIO::flush;

is_deeply( \@got, [ 'read', Errno::ESPIPE ], 'read fail' );

my $to_write = 'hello';

IO::AIO::Promiser::write($s, 0, length $to_write, $to_write, 0)->catch(
    sub { @got = ('write', 0 + shift) },
);

IO::AIO::flush;

is_deeply( \@got, [ 'write', Errno::ESPIPE ], 'write fail' );

#{
#    open my $fh, '>', "$dir/aaa";
#    POSIX::close( fileno $fh );
#
#    IO::AIO::Promiser::close($fh)->then(
#        sub { diag "close success???" },
#        sub { @got = 0 + shift },
#    );
#
#    IO::AIO::flush;
#
#    is_deeply( \@got, [ Errno::EBADF ], 'close fail' );
#}

#----------------------------------------------------------------------

done_testing;
