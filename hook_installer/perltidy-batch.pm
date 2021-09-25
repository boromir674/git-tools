#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use File::Spec;
use Getopt::Long qw(GetOptions);

# array that stores messages for files that need perltidying
my @ERRORS;

my @ERRORS1;    # error messages for issues remaining after tidying
my $CHECK;
my $debug = 0;
my @MODIFIED_FILES;    # files in the staged area state

GetOptions( "check" => \$CHECK ) or die "Invalid usage, stopped";

if ($CHECK) {
    _load_staged_files();
    for my $file (@MODIFIED_FILES) {
        _perltidy_check_file($file) if _is_perl_file($file);
    }
}
else {
    if ( not @ARGV ) {
        _load_staged_files();
        for my $file (@MODIFIED_FILES) {
            _perltidy_file($file) if _is_perl_file($file);
        }
    }
    else {
        print "--directory argument--\n" if $debug;
        my $dir = shift @ARGV;
        $dir or die "'$dir' is not a directory, stopped";
        my @perl_files = _get_perl_files($dir);
        for my $file (@perl_files) {
            _perltidy_file($file);
        }
    }
}

if (@ERRORS) {
    die join "", map { "ERROR: $_\n" } @ERRORS;
}

sub _perltidy_check_file {

    # param: string representing a filepath, eg "scripts/code.pm"
    # checks whether the staged state of the input file needs to be
    # perltidied, by comparing the text of the staged file before and after
    # applying it. Assumption: the input file is a perl source code file
    my $file       = shift;
    my $before_pep = `git show :$file`;

    # TODO store `git show` and reuse it.
    my $after_pep = `git show :$file | perltidy`;
    push @ERRORS, "File '$file' is not perltidied\n"
      if $before_pep ne $after_pep;

    # TODO incorporate perlcritic
    #my @violations = `git show :$file | pycodestyle -`;
    # push @ERRORS1, @violations; # map { "$file" . @violations } @violations;
    return;
}

sub _perltidy_file {

    # param: string representing a filepath, eg "scripts/code.py"
    my $file = shift;
    my $path = File::Spec->rel2abs($file);
    print "perltidy '$file'\n";
    `git show :$file | perltidy -st > $path`;

    # TODO incorporate perlcritic
    # my @violations = `git show :$file | pycodestyle -`;
    # push @ERRORS1, @violations;
    return;
}

# Nice syntactic sugar:
# this sub returns the globally accessible $PERLCRITIC OR (if not found) constructs it
#
# sub _perlcritic_obj {
#     our $PERLCRITIC ||=
#       Perl::Critic->new( -profile => "$ENV{TKHOME}/../TKSrc/TKTools/perlcriticrc", );
#     Perl::Critic::Violation::set_format("%f:%l:%c %m - %e [%p]");
#     return $PERLCRITIC;
# }

sub _is_perl_file {
    my $file = shift;
    chomp $file;
    return 1 if $file =~ qr/ (?:[[:alpha:].\/\-])+ \.p[ml] $ /x;
    my $file_buffer = `git show :$file`;
    return 1 if $file_buffer =~ qr/^#!\/(?:[[:alpha:].\/])*\/perl(?:$|\n|\h)/;
    return 1 if $file_buffer =~ qr/use warnings\;/;
    return 1 if $file_buffer =~ qr/ sub \h [\w_\-]+\(.+\) \{ /x;
    return 0;
}

sub _load_staged_files {
    my $dir = `git rev-parse --show-toplevel`;
    chomp($dir);
    -d $dir
      or die "Failed finding root directory.\nIs '$dir' a directory, stopped";
    my $out =
      `git diff --name-only --diff-filter=ACMRTUXB --staged HEAD -- $dir`;
    @MODIFIED_FILES = split /\n/, $out;
    return;
}
