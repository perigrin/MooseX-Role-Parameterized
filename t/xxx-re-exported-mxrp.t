#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my @calls;

BEGIN {
    package MyMXRP;
    use MooseX::Role::Parameterized;
    use Moose::Exporter;

    Moose::Exporter->setup_import_methods(
        also => 'MooseX::Role::Parameterized', );

}

do {

    package MyRole::LogMethod;
    BEGIN { MyMXRP->import(); }

    parameter method => (
        isa      => 'Str',
        required => 1,
    );

    role {
        my $p = shift;

        before $p->method => sub {
            push @calls, "calling " . $p->method;
        };

        after $p->method => sub {
            push @calls, "called " . $p->method;
        };

        around $p->method => sub {
            my $orig  = shift;
            my $start = 0;       # time
            $orig->(@_);
            my $end = 0;         # time

            push @calls, "took " . ( $end - $start ) . " seconds";
        };
    };
};

do {

    package MyClass;
    use Moose;
    with 'MyRole::LogMethod' => { method => 'new', };
};

is_deeply( [ splice @calls ], [], "no calls yet" );
MyClass->new;
is_deeply(
    [ splice @calls ],
    [ "calling new", "took 0 seconds", "called new" ],
    "instrumented new"
);

done_testing;
