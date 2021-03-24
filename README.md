# NAME

IO::AIO::Promiser - Promise interface around [IO::AIO](https://metacpan.org/pod/IO::AIO)

<div>
    <a href='https://coveralls.io/github/FGasper/p5-IO-AIO-Promiser?branch=main'><img src='https://coveralls.io/repos/github/FGasper/p5-IO-AIO-Promiser/badge.svg?branch=main' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

(This example uses [AnyEvent::AIO](https://metacpan.org/pod/AnyEvent::AIO) for conciseness; see below for examples
of setup with [IO::Async](https://metacpan.org/pod/IO::Async) and [Mojolicious](https://metacpan.org/pod/Mojolicious).)

To slurp with [AnyEvent](https://metacpan.org/pod/AnyEvent):

    use AnyEvent::AIO;

    use IO::AIO::Promiser ':all';

    my $cv = AnyEvent->condvar();

    aio_slurp("/etc/services", 0, 0)->then(
        sub { $cv->(@_) },
        sub { $cv->croak(@_) },
    );

    print $cv->recv();

It’s a bit like [Coro::AIO](https://metacpan.org/pod/Coro::AIO), but with async/await rather than [Coro](https://metacpan.org/pod/Coro),
and more proactive error-checking.

# DESCRIPTION

[IO::AIO](https://metacpan.org/pod/IO::AIO) is great, but its callback-driven interface is less so.
This module wraps IO::AIO so you can easily use promises with it instead.

Its returned promises are [Promise::XS::Promise](https://metacpan.org/pod/Promise::XS::Promise) instances.

# FUNCTIONS

This module doesn’t (yet?) cover everything IO::AIO can do.
If there’s functionality you’d like to have, create a feature request.

The following are like their [IO::AIO](https://metacpan.org/pod/IO::AIO) counterparts, but the final
callback argument is omitted, and a promise is returned instead.
That promise’s resolution is the callback’s success-case return, and
the rejection is the callback’s failure-case return.

- `wd` and `realpath()`
- `open()` (NB: The resolution is an oddity: a filehandle that is
**not** a GLOB reference.)
- `seek()`
- `close()`
- `read()` and `write()`
- `readdir()` and `readdirx()`
- `stat()` and `lstat()`
- `mkdir()` and `rmdir()`
- `chown()` and `chmod()`
- `utime()`
- `unlink()`
- `link()`, `symlink()`, and `readlink()`
- `rename()` and `rename2()`

The following are a bit different—but with good reason!—from the
corresponding IO::AIO interface:

- `slurp()` - The promise resolves to the file content,
so you don’t need to initialize a separate `$data` scalar.

# EXPORT INTERFACE

Since it’s clunky to have to type `IO::AIO::Promiser::open`, if you
pass `:all` to this module on import you’ll get `aio_*` aliases
exported into your namespace, so you can call, e.g., `aio_open` instead.
This matches IO::AIO’s own calling convention.

# EXAMPLE: [IO::Async](https://metacpan.org/pod/IO::Async) INTEGRATION

NB: See [IO::FDSaver](https://metacpan.org/pod/IO::FDSaver)’s documentation for why that module is needed.

    use IO::Async::Loop;
    use IO::FDSaver;
    use IO::AIO::Promiser ':all';

    my $loop = IO::Async::Loop->new();

    my $fdstore = IO::FDSaver->new();

    $loop->watch_io(
        handle => $fdstore->get_fh( IO::AIO::poll_fileno ),
        on_read_ready => \&IO::AIO::poll_cb,
    );

    aio_slurp("/etc/services", 0, 0)->then(
        sub { print shift },
        sub { warn shift },
    )->finally( sub { $loop->stop() } );

    $loop->run();

# EXAMPLE: [Mojolicious](https://metacpan.org/pod/Mojolicious) INTEGRATION

Mojolicious is similar to IO::Async, with the same need for [IO::FDSaver](https://metacpan.org/pod/IO::FDSaver):

    use Mojo::IOLoop;
    use IO::FDSaver;
    use IO::AIO::Promiser ':all';

    my $fdstore = IO::FDSaver->new();

    my $aio_fh = $fdstore->get_fh( IO::AIO::poll_fileno );

    Mojo::IOLoop->singleton->reactor->io( $aio_fh, \&IO::AIO::poll_cb );
    Mojo::IOLoop->singleton->reactor->watch( $aio_fh, 1, 0 );

    # NB: These are Promise::XS::Promise objects, not Mojo::Promise.
    # So there’s no wait() method, etc.
    aio_slurp("/etc/services", 0, 0)->then(
        sub { print shift },
        sub { warn shift },
    )->finally( sub { Mojo::IOLoop->stop() } );

    Mojo::IOLoop->start();

# AUTHOR & COPYRIGHT

Copyright 2021 Gasper Software Consulting

# LICENSE

This library is licensed under the same license as Perl.
