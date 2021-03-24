# NAME

IO::AIO::Promiser - Promise interface around [IO::AIO](https://metacpan.org/pod/IO::AIO)

<div>
    <a href='https://coveralls.io/github/FGasper/p5-IO-AIO-Promiser?branch=main'><img src='https://coveralls.io/repos/github/FGasper/p5-IO-AIO-Promiser/badge.svg?branch=main' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

(This example uses [AnyEvent::AIO](https://metacpan.org/pod/AnyEvent::AIO) for conciseness; it’s not difficult
to adapt it for use with, e.g., [IO::Async](https://metacpan.org/pod/IO::Async) or [Mojolicious](https://metacpan.org/pod/Mojolicious).)

To slurp with [AnyEvent](https://metacpan.org/pod/AnyEvent) and [Promise::AsyncAwait](https://metacpan.org/pod/Promise::AsyncAwait):

    use AnyEvent::AIO;
    use Promise::AsyncAwait;

    use IO::AIO::Promiser ':all';

    async sub slurp ($abs_path) {
        my $fh = await aio_open($abs_path, Fcntl::O_RDONLY, 0);

        my $buf = q<>;
        1 while await aio_read($fh, undef, 65536, $buf, length $buf);

        return $buf;
    }

… and now you can:

    my $cv = AnyEvent->condvar();

    slurp("/etc/services")->then(
        sub { $cv->(@_) },
        sub { $cv->croak(@_) },
    );

    my $content = $cv->recv();

It’s a bit like [Coro::AIO](https://metacpan.org/pod/Coro::AIO), but with async/await rather than [Coro](https://metacpan.org/pod/Coro),
and more proactive error-checking.

See below for examples of setup with [IO::Async](https://metacpan.org/pod/IO::Async) and [Mojolicious](https://metacpan.org/pod/Mojolicious).

# DESCRIPTION

[IO::AIO](https://metacpan.org/pod/IO::AIO) is great, but its callback-driven interface is less so.
This module wraps IO::AIO so you can easily use promises with it instead.

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

# AUTHOR & COPYRIGHT

Copyright 2021 Gasper Software Consulting

# LICENSE

This library is licensed under the same license as Perl.
