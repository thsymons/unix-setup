#!/usr/bin/perl
# Extensible Options Handling Package
# Supports external or user defined options and recursive options.
# Recursive options are options that can be defined with other options.
# Also supports three option handling phases, so specific options can be handled early,
# while others are handled late.  All options in one phase are processed before moving
# on to the next phase.  Each phase may add options to the current or future phases.

# Supports GetOptions::Long style option definitions and capabilities, but does not use
# GetOptions::Long package (needed more control to implement additions).

# Options can be given on command line or in any number of options files.
# Control files can call options by passing them as a string argument to use_option().
# Option is passed to 'use_option' just as it is passed on cmdline.
# For example:
#
# use_option "-setvar MY_VAR=123";
#
# Options are first collected from all option files by 'eval'ing them.  No processing of
# options occurs at this time, but new options can be defined at this time. This
# makes the ordering of options generally unimportant, although not entirely.  Options
# can be defined in any of the options files by calling def_option().  An option
# can be used on command line or with call to use_option() prior to it being defined.
# Options will be continually re-processed until no new options are defined.  Any remaining
# options (because no definition found) will be left in @ARGV array (even ones from options 
# files).

# After all options files are 'eval'ed, then the options from the command line are collected.

# As options are collected, the option reference is recorded, and any processing associated
# with the option is posted to the three command queues - the precmd, cmd and postcmd queues.
# The option definition determines what processing occurs and in which queue(s) it will be
# placed.  Processing is either a reference to other options or a subroutine call.  Option
# values are passed along as appropriate by replacing <VAL> with the option value.

# Next, option processing begins, starting with the 'precmd' phase.  All commands posted to
# the precmd queue are processed by posting referenced options or calling referenced subroutines.
# New options referenced are processed immediately if they are assigned to a previously completed
# phase.  If they are assigned to the current phase or subsequent, then they are posted to the 
# end of the current queue for that phase.  Processing of a phase continues until its queue
# is emptied.  Processing of each phase does not begin automatically - it must be explicity
# requested with a call to ExecXopts().  This allows the client script to do any desired
# processing between phases.

# There are three general types of options:
#
#   1. Simple options that are are referenced or not
#   2. Options that set variables
#   3. Options that do user-defined processing
#
# The first type are common options as normally used in scripts.  The second type set
# either environment variables or entries in the %gbl hash.  Subroutines may also
# be used here to process the variable values.  The third type call a user-defined subroutine
# and do whatever is desired, but typically not primary script processing.  This could be done,
# but is generally not recommended.  The option processing just wants to setup all the requirements
# and then let the script go about its business as normal.

# The 'precmd' phase is generally where any initial option expansion is done.  Options that
# reference other options are expanded.  This occurs recursively until all expansion is done.

# The 'cmd' phase is generally where user-defined variable manipulation occurs.  Additional
# option expansion can occur here and will generally occur immediately when referenced (assuming
# they are mapped to the 'precmd' phase).

# The 'postcmd' phase is where any user-defined processing occurs after all options and variables
# that may control this step have been processed.  This step basically treats the options and
# variables as parameters that control the processing required to setup the script to begin
# its primary work.  For example, building or locating control files or data files for the script 
# to work with or setting final environment variables to tools needed.

# When options are defined, you must specify what they should do by placing commands in the
# precmd, cmd or postcmd named arguments to the def_option() subroutine.  Note that you can
# specify commands in one or more phases.  You can specify one or more commands in each phase.
# Commands can specify other options or reference subroutines to be called.  For example:
#
#    cmd=>["-setvar MY_VAR=1", "&my_sub <VAL>"],
#
# Each option or subroutine call must be specified as a separate array element as shown above.
# Note that <VAL> may be specified zero or more times and will be replaced by the option value.
# Note also that if only one command is specified, it does not need to be wrapped in '[]'.
# Note that user defines subroutines must be refereenced as &main::my_sub.

# When options are called with use_option(), the option will be immediately expanded and
# the resulting commands will be placed in the command queues defined with the option.  You
# may optionally override the command queue to be used with the 'phase' named argument to
# use_option.  For example:

#    use_option "-setvar MY_VAR=<VAL>"; # uses default phases
#    use_option "-setvar MY_VAR=<VAL>", phase=>"cmd"; # All cmds expanded to 'cmd' queue

# Processing help:
# The help display is automatically generated from the defined options, but the client
# script must call help as desired.  You can call show_help() to display the auto-generated
# help message.  You must exit yourself if that is desired.  The -help option will be automatically
# called when the precmd phase is processed, else you must call show_help() yourself. Either
# way, you must exit yourself.  You can call option_given("help") at any time after the first
# call to GetXopts() to determine if -help was given.  It is recommended that you eval all
# options files before calling show_help(), so that any options defined there will be
# displayed.
#
# 
# General option usage:
# You can determine if an option has been used by calling option_given("opt") and passing
# it the desired option.  option_given() returns 1 if the option has been used, else it
# returns undef.  You can retrieve the value of the option with option_value("opt").
# option_value returns a scalar or an array reference, depending on whether the option
# can be given one or more times ('@' specification in option definition or not).
# option_value() also returns undef if option was not given.

package Misc::xopts;

use Text::ParseWords;
use Storable;
use strict vars;
use warnings;

my $VERSION   = 1.00;
use Exporter();
our @ISA      = qw(Exporter);
our @EXPORT   = qw(def_option delete_option use_option set_default
                option_given option_value use_option def_option_group
                show_help help_prelude dumpvars config show_given_options
                setvar unsetvar setvar_tail);
my $primary   = undef;
my $save_primary = undef;

my @local_subs = qw(set_debug setvar setenv unsetvar unsetenv setvar_tail setenv_tail);
my %local_subs;

# Class constructor
sub new {
   my ($class) = @_;
   $class = (ref $class) || $class;
   my $self = bless {}, $class;
   $self->{opts_db} = {};# hash of defined options - see def_option()
   $self->{alias} = {};# mapping of aliases to root option
   $self->{gbl} = {};# hash of global variables
   $self->{option_groups}{0} = "Setup Options";
   $self->{phase_list} = [qw(precmd cmd postcmd)];
   $self->{current_option_group} = 0;
   $self->{last_option_group} = 0;
   $self->{help_prelude} = ();
   $self->{passthru} = 0;
   $self->{debug} = 0;
   $self->{max_iterations} = 10;
   $self->{argv_processed} = 0;
   $self->{ENV} = {};
   $self->init_options();
   $self->clear();
   unless (defined $primary) {
      $primary = $self; 
      $save_primary = $primary;
      foreach (@local_subs) {
         $local_subs{$_} = 1;
      }
   }
   return $self;
}

# Set given xopts class object as primary xopts object
# syntax: $xo->set_as_primary();
sub set_as_primary {
  my $self = shift;
  $primary = $self;
}

# Restore xopts primary object pointer
sub restore_primary {
  $primary = $save_primary;
}

# Clear all given options, but retain defined options
sub clear {
   my $self = shift;
   $self->{xopts} = {};# hash of phases, each an array of options given
   $self->{given} = {};# hash of options given
}

# Copy defined and given options from given object
sub copy {
   my ($self, $from) = @_;
   $self->{opts_db} = Storable::dclone($from->{opts_db});
   $self->{given} = Storable::dclone($from->{given});
   $self->{alias} = Storable::dclone($from->{alias});
}

# merge defined options and global variables from given object
sub merge {
   my ($self, $from) = @_;
   my $current_grp = $self->{last_option_group};
   foreach my $grp (1..$from->{last_option_group}) {
      $self->def_option_group($from->{option_groups}{$grp});
   }
   foreach (keys %{$from->{opts_db}}) {
      if ($from->{opts_db}{$_}->{group} >= 1) {
         $self->{opts_db}{$_} = Storable::dclone($from->{opts_db}{$_});
         $self->{opts_db}{$_}->{group} = $current_grp + $from->{opts_db}{$_}->{group};
      }
   }
   foreach (keys %{$from->{gbl}}) {
      $self->{gbl}{$_} = $from->{gbl}{$_};
   }
}

# Get options, post them to xopts arrays for later processing
# Syntax: $obj->GetXopts(\@ARGV);
# Options processed will be removed from given options array, others will remain
sub GetXopts {
   my ($self, $args) = @_;
   my $processed;
   my $iterations = 0;
   do {
      usage() unless $self->GetOptions($args,\$processed);
   } while ($processed && $iterations++ < $self->{max_iterations});
   if ($processed) {
      die "GetXopts: Infinite loop detected in options processing - aborting\n";
   }
   print "Leftover in ARGV: @$args\n" if $self->{debug} && defined $args;
}


# Execute given phase
# Continually re-executes prior phases when they have commands
sub ExecXopts {
   my ($self,$phase) = @_;
   print "Executing Xopts Phase: $phase\n" if $self->{debug};
   if (defined $self->{xopts}{$phase}) {
      while (scalar @{$self->{xopts}{$phase}} > 0) {
         $_ = shift @{$self->{xopts}{$phase}};
         s/^\s*//;
         if (/^&/) { # call sub
            print "ExecXopts: executing sub: $_\n" if $self->{debug};
            my ($func,$args) = /&(\S+)\s*(.*)/;
            if (exists $local_subs{$func}) {
               $self->$func($args);
            } else {
               eval "$func($args);";
            }
            if ($@) {
               print "ExecXopts: error calling sub: $func $args\n";
               die $@;
            }
         } elsif (/^-/) { # expand option
            print "ExecXopts: expanding \'$_\'\n" if $self->{debug};
            $self->use_option($_);
         }
         if ($phase ne $self->{phase_list}[0]) {
            foreach my $p (@{$self->{phase_list}}) {
               last if $p eq $phase;
               $self->ExecXopts($p);
            }
         }
      }
      $self->GetXopts();# try again
   }
}

# Expands options in given list
sub GetOptions {
   my ($self,$args,$processed,$xphase) = @_;
   my @saveargs = ();
   my $result = 1;
   $$processed = 0;
   return 1 unless defined $args;
   print "GetOptions: @$args\n" if $self->{debug};
   while (scalar @{$args} > 0) {
      $_ = shift @$args;
      my $oldarg = $_;
      s/^\s*//; s/\s*$//;
      my $opt = $_;
      if (/^-/) { # option reference
         print "Parsing option: $opt\n" if $self->{debug};
         $opt =~ s/^-+//;
         $opt = $self->{alias}{$opt} if exists $self->{alias}{$opt};# get root opt
         if (exists $self->{opts_db}{$opt}) {
            my $db = $self->{opts_db}{$opt};
            my $value = "";
            print "Option found: $_\n" if $self->{debug};
            if ($db->{type} ne "") {
               $value = shift @$args;
               print "Option type found: $_ = $db->{type} -> $value\n" if $self->{debug};
               if ($db->{type} eq "i" && $value !~ /^\d+$/) {
                  die "Invalid argument given to option \'$_\'\n" 
               }
               if ($db->{type} eq "x" && $value !~ /^[\dABCDEFabcdef]+$/) {
                  die "Invalid argument given to option \'$_\'\n" 
               }
               if (exists $db->{array}) {
                  push @{$self->{given}{$opt}}, $value;
               } else {
                  $self->{given}{$opt} = $value;
               }
            } else {
               $self->{given}{$opt} = 1;
            }
            $self->post_cmd($db,$value,$xphase);
            $$processed = 1;
         } else {
            push @saveargs, $oldarg;
         }
      } else {
         push @saveargs, $opt;
      }
   }
   @{$args} = @saveargs;
   return $result;
}

# Post given cmd to xopts reference
# Place cmd at beginning or end of xopts array, as given by db->first
sub post_cmd {
   my ($self,$db,$value,$xphase) = @_;
   foreach my $phase (@{$self->{phase_list}}) {
      if (exists $db->{$phase}) {
         foreach my $cmd ($self->get_array($db->{$phase})) {
            $cmd =~ s/<VAL>/$value/g;
            print "post_cmd: $cmd<<<\n" if $self->{debug};
            my $p = $phase;
            $p = $xphase if defined $xphase;
            if (exists $db->{first}) {
               unshift @{$self->{xopts}{$p}}, $cmd;
            } else {
               push @{$self->{xopts}{$p}}, $cmd;
            }
         }
      }
   }
}

# Returns given argument as an array, regardless of what it is
# Takes one or more scalar arguments, one or more lists, one or more references
# to lists or any combination.
# Also takes an empty list or empty reference
# Does not accept hashes
# Can be called as class method or subroutine
sub get_array {
   my $self = shift;
   my @args = @_;
   unshift @args, $self unless ref $self;
   my @array = ();
   foreach (@args) {
      if (ref($_)) {
         if (ref($_) eq "ARRAY") {
            push @array, @{$_};
         } elsif (ref($_) eq "SCALAR") {
            push @array, $$_;
         }
      } else {
         push @array, $_;
      }
   }
   return @array;
}

# Defines text to preceed option display for -help
sub help_prelude {
   my $self = shift;
   @{$self->{help_prelude}} = @_;
}

# Display all defined options
# Can be called as class method or subroutine
# syntax: show_help(msg=>"my msg", group=>"group desc");
# both named arguments are optional
sub show_help {
   my $self = shift;
   my $msg = "";
   unless (ref $self) {
      unshift @_, $self if defined $self;
      $self = $primary;
   }
   my %args = @_ if defined @_;
   my $second;
   my $group = 0;
   print "$args{msg}\n" if exists $args{msg};
   foreach (@{$self->{help_prelude}}) {
      print "$_\n";
   }
   foreach my $group (0..$self->{last_option_group}) {
      my @group_options = ();
      foreach (keys %{$self->{opts_db}}) {
         push @group_options, $_ if $self->{opts_db}{$_}->{group} == $group;
      }
      my $grp = "";
      $grp = "($group)" if $self->{debug} > 0;
      next if exists $args{group} && $args{group} ne $self->{option_groups}{$group};
      print "\n$self->{option_groups}{$group}: $grp\n";
      foreach my $opt (sort @group_options) {
         my $optd = $opt;
         my $db = $self->{opts_db}{$opt};
         next if exists $self->{opts_db}{$opt}->{hidden};
         $optd .= " $db->{type}";
         if (ref($db->{desc}) eq "ARRAY") {
            foreach (@{$db->{desc}}) {
               printf "%-16s %s\n",$optd,$_;
               $optd = "";
            }
         } else {
            printf "%-16s %s\n",$optd,$db->{desc};
         }
         $second = "";
         $second = "default=$db->{default} " if exists $db->{default};
         if (exists $db->{alias}) {
            if (ref($db->{alias}) eq "ARRAY") {
               $second .= "alias=";
               foreach (@{$db->{alias}}) {
                  $second .= "$_," 
               }
            } else {
               $second .= "alias=$db->{alias} " 
            }
         }
         print " " x 16," $second\n" if $second ne "";
      }
   }
}

# Can be called as class method or subroutine
sub dump_given_options {
   my $self = shift;
   $self = $primary unless ref $self;
   print "Dumping given options:\n";
   foreach my $opt (keys %{$self->{opts_db}}) {
      my $db = $self->{opts_db}{$opt};
   }
 }

# returns 1 if option has been given (referenced, used)
# else returns undef
# Can be called as class method or subroutine
# Always returns true option has default value
sub option_given {
   my $self = shift;
   my $opt;
   if (ref $self) {
      $opt = shift;
   } else {
      $opt = $self;
      $self = $primary;
   }
   return exists $self->{given}{$opt} || $self->{opts_db}{$opt}{default} ? 1 : undef;
}

# Returns argument value for given option
# Can be called as class method or subroutine
# Returns default value for option if one exists and option was not otherwise given
sub option_value {
   my $self = shift;
   my $opt;
   if (ref $self) {
      $opt = shift;
   } else {
      $opt = $self;
      $self = $primary;
   }
   if (exists $self->{given}{$opt}) {
      return $self->{given}{$opt};
   } else {
      if (exists $self->{opts_db}{$opt}{default}) {
         my $value = $self->{opts_db}{$opt}{default};
         if (exists $self->{opts_db}{$opt}{array}) {
            return [$value];
         } else {
            return $value;
         }
      } else {
         return undef;
      }
   }
}

# Define a new option
# Overrides any previous definition for same option
# Syntax: 
# def_option(
#     option-name[=type],
#     default=>default-value,
#     alias=>alias-value, or [alias-values]
#     desc=>"description" or ["line1", "line2", ...],
#     destination=>destination-variable-or-subroutine,
#     precmd=>'cmd-value',
#     cmd=>'cmd-value',
#     postcmd=>'cmd-value',
#     first=>1, -- place cmd at head of queue
#     hidden=>1,
#     );
# type=arg type identifier (i,s,x,i@,s@,x@).
# option is given exactly as any argument given to GetOptions, but without
# any destination value. For example:
#    def_option("mine"); # for simple option
#    def_option("mine=i"); # for integer option
# A destination is optional, and is given with 
# named argument 'destination', as in:
#    def_option("mine=s",destination=>\$var);
# Can be called as class method or subroutine
sub def_option {
   my $self = shift;
   my ($optline,%args);
   if (ref $self) {
      ($optline,%args) = @_;
   } else {
      $optline = $self;
      $self = $primary;
      (%args) = @_;
   }
   my ($opt,$type) = split('=',$optline);
   $type = "" unless defined $type;
   $self->{opts_db}{$opt} = {};
   $self->{opts_db}{$opt}->{desc} = "Unknown";
   my $db = $self->{opts_db}{$opt};
   $db->{array} = 1 if $type =~ /\@/;
   $type =~ s/\@//;
   $db->{type} = $type;
   $db->{group} = $self->{current_option_group};
   foreach my $key (keys %args) {
      $db->{$key} = $args{$key};
   }
   if (exists $args{alias}) {
      my $a = $args{alias};
      if (ref($a) eq "ARRAY") {
         my @aa = @$a;
         @{$db->{alias}} = ();
         foreach (@aa) {
            push @{$db->{alias}}, $_;
            $self->{alias}{$_} = $opt;
         }
      } else {
         $db->{alias} = $a;
         $self->{alias}{$a} = $opt;
      }
   }
   if ($self->{debug}) {
      my $vtype = "scalar";
      $vtype = "array" if exists $db->{array};
      print "def_option: $optline ($opt: $type $vtype)\n" 
   }
}

# Set default value for given option
# Syntax: set_default(option, default);
# Example: set_default "t", "testname";
#          set_defalut "-t testname";# alternative
# Can be called as class method or subroutine
sub set_default {
   my $self = shift;
   my ($opt, $optline, $default);
   if (ref $self) {
      ($optline,$default) = @_;
   } else {
      $optline = $self;
      $default = shift;
      $self = $primary;
   }
   $opt = $optline;
   $default = "" unless defined $default;
   if ($opt =~ /^\s*-(\S+)\s*/) {
      $opt = $1;
      $default = $' . $default;
   }
   $opt = $self->{alias}{$opt} if exists $self->{alias}{$opt};
   print "set_default $opt -> $default\n" if $self->{debug};
   $self->{opts_db}{$opt}->{default} = $default;
}

 # Define new option group - options are sorted by this grouping
# If group already exists, then just sets that as current group.
# New defined options will be assigned to current group.
# Just give description of group here - it will get next group number automatically
# Can be called as class method or subroutine
sub def_option_group {
   my $self = shift;
   my $desc;
   if (ref $self) {
      $desc = shift;
   } else {
      $desc = $self;
      $self = $primary;
   }
   my $grp = -1;
   foreach (keys %{$self->{option_groups}}) {
      $grp = $_ if $self->{option_groups}{$_} eq $desc;
   }
   if ($grp > -1) { # existing group
      $self->{current_option_group} = $grp;
   } else { # new group
      $self->{last_option_group}++;
      $self->{option_groups}{$self->{last_option_group}} = $desc;
      $self->{current_option_group} = $self->{last_option_group};
   }
}

# Delete option from database
sub delete_option {
   my ($self, $option) = @_;
   delete $self->{opts_db}{$option};
}

# Specify an option to use, just as if given on cmd line
# Syntax: use_option("option string", phase=>PPP);
# Where PPP="precmd", "cmd" or "postcmd"
# Can be called as class method or subroutine
sub use_option {
   my $self = shift;
   my ($cmd, %args);
   if (ref $self) {
      ($cmd, %args) = @_;
   } else {
      $cmd = $self;
      (%args) = @_;
      $self = $primary;
   }
   my @cmds = shellwords($cmd);
   my $processed;
   my $phase = $args{phase};
   $self->GetOptions(\@cmds, \$processed, $phase);
   push @ARGV, @cmds if scalar @cmds;
}

sub extract_options {
   my ($self,$opt,$optfiles) = @_;
   foreach my $optfile (@{$optfiles}) {
      print "Processing defopts file: $optfile\n";
      do $optfile;
   }
}

# Set user 'variable' to given value.
# User variables are defined as elements in gbl hash
# Can be called as class method or subroutine
sub setvar {
   my $self = shift;
   my $arg;
   if (ref $self) {
      $arg = shift;
   } else {
      $arg = $self;
      $self = $primary;
   }
   if ($arg =~ /(\w+)([+:=]+)(.*)/) {
      $self->{gbl}{$1} = $3 if $2 eq "=";
      $self->{gbl}{$1} .= $3 if $2 eq "+=";
      $self->{gbl}{$1} = $3 .$self->{gbl}{$1} if $2 eq ":=";
   } else {
      $self->{gbl}{$arg} = 1;
   }
}

# Unset (delete) variable defined with -setvar
# Can be called as class method or subroutine
sub unsetvar {
   my $self = shift;
   my $arg;
   if (ref $self) {
      $arg = shift;
   } else {
      $arg = $self;
      $self = $primary;
   }
   delete $self->{gbl}{$arg};
}

# Replace 'tail' portion of path in given global variable
# Syntax: setvar_tail("env-variable=tail");
# Can be called as class method or subroutine
sub setvar_tail {
   my $self = shift;
   my $arg;
   if (ref $self) {
      $arg = shift;
   } else {
      $arg = $self;
      $self = $primary;
   }
   my ($var, $tag) = split(/=/,$arg);
   my $path;
   if (exists $self->{gbl}{$var}) {
      $path = $self->{gbl}{$var};
      $path =~ s/\/+$//;
      $path =~ s/\/[^\/]+$//;
      $path .= "/$tag";
      $self->{gbl}{$var} = $path;
   } else {
      $self->{gbl}{$var} = $tag;
   }
   print "setvar_tail: $var => $path\n" if $self->{debug};
}

# Set user 'variable' to given value.
# User variables are defined as elements in gbl hash
sub setenv {
   my ($self,$arg) = @_;
   if ($arg =~ /(\w+)([+:=]+)(.*)/) {
      $ENV{$1} = $3 if $2 eq "=";
      $ENV{$1} .= $3 if $2 eq "+=";
      $ENV{$1} = $3 .$ENV{$1} if $2 eq ":=";
      $self->{ENV}{$1} = $ENV{$1};
   } else {
      $ENV{$arg} = 1;
      $self->{ENV}{$arg} = 1;
   }
}

# Unset (delete) variable defined with -setvar
sub unsetenv {
   my ($self,$var) = @_;
   delete $ENV{$var};
   delete $self->{ENV}{$var};
}

# Replace 'tail' portion of path in given environment variable
# Syntax: setenv_tail("env-variable=tail");
sub setenv_tail {
   my ($self,$arg) = @_;
   my ($var, $tag) = split(/=/,$arg);
   my $path;
   if (exists $ENV{$var}) {
      $path = $ENV{$var};
      $path =~ s/\/+$//;
      $path =~ s/\/[^\/]+$//;
      $path .= "/$tag";
      $ENV{$var} = $path;
   } else {
      $ENV{$var} = $tag;
   }
   print "setenv_tail: $var => $path\n" if $self->{debug};
}

# Dump variables defined with '-setvar' and '-setenv'
sub dumpvars {
   my $self = shift;
   print "Dump variables defined with -setvar:\n";
   foreach my $key (keys %{$self->{gbl}}) {
      print "gbl->{$key} = $self->{gbl}{$key}\n";
   }
   print "Dump variables defined with -setenv:\n";
   foreach my $key (keys %{$self->{ENV}}) {
      print "ENV{$key} = $self->{ENV}{$key}\n";
   }
}

# Can be called as class method or subroutine
sub set_debug {
   my $self = shift;
   if (ref $self) {
      $self->{debug} = shift;
   } else {
      $primary->{debug} = shift;
   }
}

sub config {
   my $self = shift;
   foreach my $arg (@_) {
      $self->{passthru} = 1 if $arg eq "passthru";
      $self->{debug} = 1 if $arg eq "debug";
   }
}

sub show_given_options {
   my $self = shift;
   print "Given options:\n";
   foreach my $opt (keys %{$self->{opts_db}}) {
      if (option_given($opt)) {
         printf "%16s - ", $opt;
         if (exists $self->{opts_db}{$opt}->{array}) {
            my $value = option_value($opt);
            my $pad = "";
            foreach (@$value) {
               print "$pad$_\n";
               $pad = " " x 19;
            }
         } else {
            print option_value($opt) . "\n";
         }
      }
   }
}

sub init_options {
   my $self = shift;
   # Define default options
   $self->def_option_group("Setup Options");
   $self->def_option("help",
      desc=>"Displays this help message",
      alias=>"h",
      precmd=>"&show_help");
   $self->def_option("defopts=s@",desc=>"Reference options definition file",
      precmd=>"&extract_options <VAL>");
   $self->def_option("setvar=s@", 
      desc=>["Defines variable values.",
             "Use = to assign, += to append, := to prepend"],
      precmd=>"&setvar <VAL>");
   $self->def_option("unsetvar=s@",
      desc=>"Unset (delete) variables defined with -setvar",
      precmd=>"&unsetvar <VAL>", first=>1);
   $self->def_option("dumpvars", desc=>"Dump variables defined with -setvar option",
                          postcmd=>"&dumpvars");
   $self->def_option("setenv=s@", 
      desc=>["Defines/sets environment variable values.",
             "Use = to assign, += to append, := to prepend"],
      precmd=>"&setenv <VAL>");
   $self->def_option("unsetenv=s@",
      desc=>"Unset (delete) environment variables defined with -setenv",
      precmd=>"&unsetenv <VAL>", first=>1);
   $self->def_option("debug",desc=>"Enable debug displays",
      precmd=>"&set_debug 1",first=>1);
   $self->def_option("setvar_tail=s@",  desc=>"Replace tail of path in given global variable: ",
      cmd=>"&setvar_tail <VAL>");
   $self->def_option("setenv_tail=s@",  desc=>"Replace tail of path in given environment variable: ",
      cmd=>"&setenv_tail <VAL>");
}

1;
