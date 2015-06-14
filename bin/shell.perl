#!/usr/bin/perl
# Description
use Getopt::Long;
Getopt::Long::config(qw(no_bundling auto_abbrev no_ignore_case));
use File::Basename;
use Cwd qw(chdir getcwd);
use strict;
use warnings;

my $exit_value;

sub usage {
print <<EOF;
Syntax: $0 -Xh 
-X   : Debug only mode, do not execute
-h   : Display this help
EOF
exit;
}

my %opts;
usage unless &GetOptions(\%opts,
      "h","X",
      );
usage if $opts{help};
usage if @ARGV != 1;
$arg = shift @ARGV;

sub run_cmd {
   my $cmd = shift;
   print "$cmd\n" if $opts{X};
   system $cmd unless $opts{X};
   $exit_value = $? >> 8;
}

