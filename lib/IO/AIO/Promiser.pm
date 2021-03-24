package IO::AIO::Promiser;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

IO::AIO::Promiser - Promise interface around L<IO::AIO>

=head1 SYNOPSIS

(This example uses L<AnyEvent::AIO> for conciseness; it’s not difficult
to adapt it for use with, e.g., L<IO::Async> or L<Mojolicious>.)

To slurp with L<AnyEvent> and L<Promise::AsyncAwait>:

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

It’s a bit like L<Coro::AIO>, but with async/await rather than L<Coro>,
and more proactive error-checking.

See below for examples of setup with L<IO::Async> and L<Mojolicious>.

=head1 DESCRIPTION

L<IO::AIO> is great, but its callback-driven interface is less so.
This module wraps IO::AIO so you can easily use promises with it instead.

=cut

#----------------------------------------------------------------------

use Carp ();
use IO::AIO ();

use Promise::XS ();

#defined below
my %METADATA;

#----------------------------------------------------------------------

=head1 FUNCTIONS

This module doesn’t (yet?) cover everything IO::AIO can do.
If there’s functionality you’d like to have, create a feature request.

The following are like their L<IO::AIO> counterparts, but the final
callback argument is omitted, and a promise is returned instead.
That promise’s resolution is the callback’s success-case return, and
the rejection is the callback’s failure-case return.

=over

=item * C<wd> and C<realpath()>

=item * C<open()> (NB: The resolution is an oddity: a filehandle that is
B<not> a GLOB reference.)

=item * C<seek()>

=item * C<close()>

=item * C<read()> and C<write()>

=item * C<readdir()> and C<readdirx()>

=item * C<stat()> and C<lstat()>

=item * C<mkdir()> and C<rmdir()>

=item * C<chown()> and C<chmod()>

=item * C<utime()>

=item * C<unlink()>

=item * C<link()>, C<symlink()>, and C<readlink()>

=item * C<rename()> and C<rename2()>

=back

The following are a bit different—but with good reason!—from the
corresponding IO::AIO interface:

=over

=item * C<slurp()> - The promise resolves to the file content,
so you don’t need to initialize a separate C<$data> scalar.

=cut

sub slurp {
    my $d = Promise::XS::deferred();

    my $data;

    &IO::AIO::aio_slurp( @_[0 .. 2], $data, sub {
        if ($_[0] >= 0) {
            $d->resolve($data);
        }
        else {
            $d->reject($!);
        }
    } );

    $d->promise();
}

=back

=cut

#----------------------------------------------------------------------

=head1 EXPORT INTERFACE

Since it’s clunky to have to type C<IO::AIO::Promiser::open>, if you
pass C<:all> to this module on import you’ll get C<aio_*> aliases
exported into your namespace, so you can call, e.g., C<aio_open> instead.
This matches IO::AIO’s own calling convention.

=cut

sub _create_func {
    my $fn = shift;

    my $metadata_ar = $METADATA{$fn} or do {
        Carp::confess sprintf("Bad function: %s::%s", __PACKAGE__, $fn);
    };

    my ($limit, $resolver_cr) = @$metadata_ar;
    $resolver_cr ||= \&_create_defined_resolver;

    my $ioaio_cr = IO::AIO->can("aio_$fn") or do {
        Carp::confess "IO::AIO::aio_$fn is missing!";
    };

    my $new_cr = sub {
        my $d = Promise::XS::deferred();

        $ioaio_cr->( @_[0 .. $limit], $resolver_cr->($d) );

        $d->promise();
    };

    {
        no strict 'refs';
        *$fn = $new_cr;
    }

    return $new_cr;
}

#----------------------------------------------------------------------

sub _create_defined_resolver {
    my $d = $_[0];

    return sub {
        if (defined $_[0]) {
            $d->resolve($_[0]);
        }
        else {
            $d->reject($!);
        }
    };
}

sub _create_negative_resolver {
    my $d = $_[0];

    return sub {
        if ($_[0] >= 0) {
            $d->resolve($_[0]);
        }
        else {
            $d->reject($!);
        }
    };
}

BEGIN {
    %METADATA = (
        wd => [0],
        realpath => [0],

        open => [2],
        close => [0],
        seek => [2, \&_create_negative_resolver],
        read => [4, \&_create_negative_resolver],
        readdir => [0],
        readdirx => [1],
        write => [4, \&_create_negative_resolver],
        stat => [0],
        lstat => [0],
        utime => [2],
        chown => [2],
        chmod => [1],
        unlink => [0],
        mkdir => [1],
        rmdir => [0],
        link => [1],
        rename => [1],
        rename2 => [2],
        symlink => [1],
        readlink => [0],
        truncate => [1],
    );

    _create_func($_) for keys %METADATA;
}

sub import {
    my $ns = (caller 1)[0];
    my $opt = $_[1];

    if ($opt) {
        my @to_import;

        if ($opt eq ':all') {
            @to_import = keys %METADATA;
        }
        else {
            Carp::confess sprintf "%s: Bad import parameter: %s", __PACKAGE__, $opt;
        }

        no strict 'refs';
        *{"${ns}::aio_$_"} = __PACKAGE__->can($_) for @to_import;
    }

    return;
}

1;

#----------------------------------------------------------------------

=head1 AUTHOR & COPYRIGHT

Copyright 2021 Gasper Software Consulting

=head1 LICENSE

This library is licensed under the same license as Perl.

=cut
