#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Socket;
use Fcntl;
use Errno;
use POSIX;
use Config;

use IO::AIO;
use IO::AIO::Promiser;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

socket my $s, Socket::AF_INET, Socket::SOCK_STREAM, 0;

my @got;

IO::AIO::Promiser::open("$dir/ha/ha", Fcntl::O_CREAT, 0)->catch(
    sub { @got = 0 + shift },
);

IO::AIO::flush;

is_deeply( \@got, [ Errno::ENOENT ], 'open fail' );

{
    open my $fh, '>', "$dir/aaa";
    POSIX::close( fileno $fh );

    IO::AIO::Promiser::close($fh)->then(
        sub { diag "close success???" },
        sub { @got = 0 + shift },
    );

    IO::AIO::flush;

    is_deeply( \@got, [ Errno::EBADF ], 'close fail' );
}

#----------------------------------------------------------------------

done_testing;
