#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use File::Spec;
use Getopt::Long qw(GetOptions);

# array that stores messages for files that need autopeping
my @ERRORS;

my @ERRORS1;
my $CHECK;
my $debug = 0;
my @MODIFIED_FILES;

GetOptions( "check" => \$CHECK ) or die "Invalid usage";

if ($CHECK) {
    _load_staged_files();
    for my $file (@MODIFIED_FILES) {

        _autopep_check_file($file) if _is_python_file($file);
    }
}
else {
    if ( not @ARGV ) {
        _load_staged_files();
        for my $file (@MODIFIED_FILES) {
            _autopep_file($file) if _is_python_file($file);
        }
    }
    else {
        my $dir = shift @ARGV;
        $dir or die "'$dir' is not a directory, stopped";
        my @python_files = _get_python_files($dir);
        for my $file (@python_files) {
            _autopep_file($file);
        }
    }
}

if (@ERRORS) {
    die join "", map { "ERROR: $_\n" } @ERRORS;
}

sub _autopep_check_file {

    # param: string representing a filepath, eg "scripts/code.py"
    # checks whether the staged state of the input file needs to be autopeped,
    # by comparing the text of the staged file before and after applying autopep
    # my $state_after_autopep8 = `$staged_state_of_file | autopep8 -aaaa -`;
    # my $staged_state_of_file = `git show :$file`;

    my $file       = shift;
    # my $level = shift;
    # my $level_a = "";
    # for (1..5) { $level_a = "$(level_a)a"; } 
    my $after_pep  = `git show :$file | autopep8 -aaaa -`;
    my $before_pep = `git show :$file`;

    # assumption: the input file is a python file
    # autopep8 -aaaa to it.
    push @ERRORS, "File '$file' is not tidied\n" if $before_pep ne $after_pep;
    my @violations = `git show :$file | pycodestyle -`;
    push @ERRORS1, @violations;    # map { "$file" . @violations } @violations;
    return;
}

sub _autopep_file {

    # param: string representing a filepath, eg "scripts/code.py"
    my $file = shift;
    my $path = File::Spec->rel2abs($file);
    print "autopep '$file'\n";
    `git show :$file | autopep8 -aaaa - > $path`;
    my @violations = `git show :$file | pycodestyle -`;
    push @ERRORS1, @violations;
    return;
}

sub _is_python_file {
    my $file = shift;    # input is string
    chomp $file;
    return 1 if $file =~ qr/ [\w_\-\d]+\.py$ /x;
    my $file_buffer = `git show :$file`;
    return 1
    if $file_buffer =~ qr/^#!\/(?:[[:alpha:].\/])*\/python[23]?(?:$|\n|\h)/;
    #return 1 if $file_buffer =~ qr/ def \h [\w_]+\(.*\): /x;
    return 0;
}

sub _load_staged_files {
    my $dir = `git rev-parse --show-toplevel`;
    chomp $dir;
    -d $dir or die "Failed finding root directory.\nIs '$dir' a directory? stopped";
    my $out = `git diff --name-only --diff-filter=ACMRTUXB --staged HEAD -- $dir`;
    @MODIFIED_FILES = split /\n/, $out;
    return;
}
