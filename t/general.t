#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Fcntl;
use Errno;
use Config;

use File::Temp;

use IO::AIO;
use IO::AIO::Promiser;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my @success;

IO::AIO::Promiser::open("$dir/file", Fcntl::O_CREAT | Fcntl::O_RDWR, 0644)->then(
    sub { push @success, \do { my $v = shift } },
);

IO::AIO::flush;

my $fh = $success[0];

isa_ok( $fh, 'GLOB', 'resolution of open()' );

my $to_write = "hello";
IO::AIO::Promiser::write($fh, undef, length $to_write, $to_write, 0)->then(
    sub { @success = ('write', shift) },
);

IO::AIO::flush;

is_deeply( \@success, ['write', length $to_write], 'success on write' );

IO::AIO::Promiser::seek($fh, 0, 0)->then(
    sub { @success = 'seek' },
);

IO::AIO::flush;

is_deeply( \@success, ['seek'], 'success on seek' );

my $data = q<>;
IO::AIO::Promiser::read($fh, 0, 20, $data, 0)->then(
    sub { @success = ('read', shift) },
);

IO::AIO::flush;

is_deeply( \@success, ['read', length $to_write], 'success on read' );

is($data, $to_write, '… and the buffer is filled');

IO::AIO::Promiser::slurp("$dir/file", 0, 0)->then(
    sub { @success = ('slurp', shift) },
);

IO::AIO::flush;

is_deeply( \@success, ['slurp', $to_write], 'success on slurp' );

#----------------------------------------------------------------------

IO::AIO::Promiser::stat($fh)->then(
    sub { @success = ('stat', (stat _)[7]) },
);

IO::AIO::flush;

is_deeply( \@success, ['stat', length $to_write], 'success on stat' );

IO::AIO::Promiser::lstat($fh)->then(
    sub { @success = ('lstat', (stat _)[7]) },
);

IO::AIO::flush;

is_deeply( \@success, ['lstat', length $to_write], 'success on lstat' );

IO::AIO::Promiser::utime($fh, 123, 456)->then(
    sub { @success = ('utime', (stat $fh)[8,9]) },
);

IO::AIO::flush;

is_deeply( \@success, ['utime', 123, 456], 'success on utime' );

IO::AIO::Promiser::chmod($fh, 0444)->then(
    sub { @success = ('chmod', (stat $fh)[2] & 0777) },
);

IO::AIO::flush;

is_deeply( \@success, ['chmod', 0444], 'success on chmod' );

IO::AIO::Promiser::truncate($fh, (length $to_write) - 1)->then( sub {
    @success = ('truncate', -s $fh);
} );

IO::AIO::flush;

is_deeply( \@success, ['truncate', (length $to_write) - 1], 'success on truncate' );

IO::AIO::Promiser::link("$dir/file", "$dir/dupe")->then(
    sub { @success = ('link', -e "$dir/dupe") },
);

IO::AIO::flush;

is_deeply( \@success, ['link', 1], 'success on link' );

IO::AIO::Promiser::readdir($dir)->then(
    sub { @success = ('readdir', sort @{ shift() } ) },
);

IO::AIO::flush;

is_deeply( \@success, ['readdir', 'dupe', 'file'], 'success on readdir' );

IO::AIO::Promiser::unlink("$dir/file")->then(
    sub { @success = ('unlink', -e "$dir/file") },
);

IO::AIO::flush;

is_deeply( \@success, ['unlink', undef], 'success on unlink' );

#----------------------------------------------------------------------

@success = ();

IO::AIO::Promiser::mkdir("$dir/mydir", 0)->then( sub {
    push @success, 'mkdir';
} );

IO::AIO::flush;

is_deeply( \@success, ['mkdir'], 'success on mkdir' );

IO::AIO::Promiser::rmdir("$dir/mydir")->then( sub {
    push @success, 'rmdir';
} );

IO::AIO::flush;

is_deeply( \@success, ['mkdir', 'rmdir'], 'success on rmdir' );

#----------------------------------------------------------------------

SKIP: {
    skip "No symlink() in $^O", 1 if !$Config{'d_symlink'};

    IO::AIO::Promiser::symlink("heyhey", "$dir/symlink")->then( sub {
        @success = ('symlink', readlink "$dir/symlink");
    } );

    IO::AIO::flush;

    is_deeply( \@success, ['symlink', 'heyhey'], 'success on symlink' );

    IO::AIO::Promiser::readlink("$dir/symlink")->then( sub {
        @success = ('readlink', shift);
    } );

    IO::AIO::flush;

    is_deeply( \@success, ['readlink', 'heyhey'], 'success on readlink' );

    IO::AIO::Promiser::rename("$dir/symlink", "$dir/renamed")->then( sub {
        @success = ('rename', readlink "$dir/renamed");
    } );

    IO::AIO::flush;

    is_deeply( \@success, ['rename', 'heyhey'], 'success on rename' );

    symlink 'dummy', "$dir/symlink";

  SKIP: {
        skip "Linux only, not $^O!", 1 if $^O ne 'linux';

        my @success = ();

        IO::AIO::Promiser::rename2("$dir/renamed", "$dir/symlink", IO::AIO::RENAME_NOREPLACE)->then(
            sub { diag "XXXX succeeded??" },
            sub { @success = ('rename2', 0 + shift); },
        );

        IO::AIO::flush;

        is_deeply( \@success, ['rename2', Errno::EEXIST], 'no clobber' );
    }
}

done_testing();

1;
