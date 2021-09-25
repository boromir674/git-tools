#!/usr/bin/perl

use utf8;
use Cwd qw();
use File::Spec;
use Carp;
use strict;
use warnings;

my $debug = 1;

# known available hooks to inteface with
my %hooks_hash = (
    "applypatch-msg.sample"     => 1,
    "commit-msg.sample"         => 1,
    "post-update.sample"        => 1,
    "pre-applypatch.sample"     => 1,
    "pre-commit"                => 1,
    "prepare-commit-msg.sample" => 1,
    "pre-push.sample"           => 1,
    "pre-rebase.sample"         => 1,
    "update.sample"             => 1
);

my $hook_from = shift @ARGV;
my $hook_type = shift @ARGV;
my $hook_to   = shift @ARGV;

-e $hook_to or die "No hook found to load; stopped";
$hooks_hash{$hook_type} or die "Hook '$hook_type' is not available; stopped";
-d $hook_from or die "I'm sorry, '$hook_from' is not a directory; stopped";

my $pwd = Cwd::cwd();
chdir($hook_from);
my $root = `git rev-parse --show-toplevel`;
chomp $root;
chdir($pwd);
-d $root or die "I'm sorry, '$root' is not the root of a git repo";

sub get_bak_count {
    opendir( DIR, "$root/.git/hooks" );
    my @files = grep( /\.bak\d\d?$/, readdir(DIR) );
    print "" . join( ", ", @files ) if $debug;
    my $count = scalar @files;
    print "count $count\n" if $debug;
    return $count;
}

# back up existing hook of same type
my $a_hook = $root . "/.git/hooks/" . $hook_type;

if ( -e $a_hook ) {
    my $v = get_bak_count();
    print "Executing mv $a_hook $a_hook.bak$v\n" if $debug;
    `mv $a_hook $a_hook.bak$v`;
}

# all the installation is really this command(s)!
my $path0 = File::Spec->rel2abs($hook_to);
`ln -s $path0 $root/.git/hooks/$hook_type`;
print
"Installed '$hook_to' as a '$hook_type' hook in '$root/.git/hooks/$hook_type'\n";

