#!/usr/bin/perl
# Simulation build and run script

use Misc::xopts;
use Misc::SimUtil;
use Text::ParseWords;
use Cwd qw(chdir getcwd);
use File::Basename;
use strict;
use warnings;

my @test_lines;
my $exit_value = 0;
my $abort_ok = 1;
my %testdb;
my %tests_run;
our %mwa_branches;
our %mwa_dependents;

our $xm = Misc::xopts->new();# primary cmdline options
our $gbl = $xm->{gbl};
our %gblvar;# for backward compatibility
our $xt = Misc::xopts->new();# test options
our $quiet;
our $debug;
our $cwd;
our %client;
our $testname;
my $execute_count = 0;

$gbl->{GBL_BUILDOPTS} = "";
$gbl->{GBL_RUNOPTS} = "";

#$xm->config(qw(debug));
#$xt->config(qw(debug));
#Misc::SimUtil::enable_debug_msgs();

def_option_group("Build Options");
def_option "top=s",       desc=>"Top-level module name";
def_option "results=s",   desc=>"Subdirectory for all compile and sim results",
                          precmd=>"&setvar RESULTS=<VAL>";
def_option "batch=s",     desc=>"Subdirectory for sim results",
                          precmd=>"&setvar BATCH=<VAL>";
def_option "buildopts=s@",desc=>["Options to be passed down to 'irun' for building model",
                                 "Must be quoted"];
def_option "rbopts=s@", 
                          desc=>["Options to be passed down to 'irun' for building AND running model",
                                 "Must be quoted"];
def_option "clean",       desc=>"Delete all output directories prior to model build";
def_option "C",           desc=>"Do NOT Compile - simulate only";
def_option "ovm",         desc=>"Use Cadence OVM source, instead of OVM World release";
def_option "ovmhome",     desc=>"Use \$GCO_OVM as source directory for OVM code";
def_option "profile",     desc=>"Enable performance profiling", precmd=>"-rbopts -profile";
def_option "linedebug",   desc=>"Compile to enable source code single-stepping", 
                          precmd=>"-buildopts -linedebug";
def_option "build_dir=s", desc=>"Simulation model build directory";
def_option "errormax=n",  desc=>"Terminate compile after N errors (default = 3)";

def_option_group("Sim Execution Options");
def_option "tl=s",        desc=>"Testlist to execute";
def_option "t=s",         desc=>"Name of test to execute, or ALL to execute all test";
def_option "tm=s",        desc=>"Run all tests matching given regular expressions";
def_option "xt=s",        desc=>"Execute given test, without requiring definition in testlist";
def_option "gui",         desc=>"Launch simulation via GUI", 
                          precmd=>"-buildopts -linedebug";
def_option "loops=n",     desc=>"Run each test N times, each with different random seed",
                          alias=>["loop"];
def_option "runopts=s@",  desc=>["Options to be passed down to 'irun' for running sim",
                          "Must be quoted"];
def_option "first_runopts=s@",
                          desc=>["Same as -runopts, but placed before all -runopts options"];
def_option "verbosity=s@",desc=>"Set OVM verbosity level - NONE, LOW, MEDIUM, HIGH",
                          default=>"LOW",
                          alias=>["v","verbo","verbose"];
def_option "nodebug",     desc=>"Disables debug visibility access - speeds up simulation";
def_option "S",           desc=>"Do NOT Simulate - compile only";
def_option "recompile",   desc=>"Recompile design for each test, saving compile results in test directory";
def_option "timeout=n",   desc=>"Simulation timeout value, in us (use 0 for no timeout)",
                          precmd=>"-runopts +SIM_TIMEOUT=<VAL>";
def_option "drain=n",     desc=>"Simulation drain time value, in ns (use 0 for no drain time)",
                          precmd=>"-runopts +SIM_DRAINTIME=<VAL>";
def_option "rerun",       desc=>["Causes sim to be re-run if it fails.",
                                 "-wave option will be added for re-run"];
def_option "run_dir=s",   desc=>["Run directory - tests results also stored here",
                                 "Overrides standard directory structure"];
def_option "run_args=s", desc=>["Specify argument line to be given to \'run\' command in TCL file",
                                "that controls sim execution"];

def_option_group("Batch Processing Options");
def_option "igrid",       desc=>"Submit as interactive job to SunGrid";
def_option "grid",        desc=>"Submit job to SunGrid";
def_option "select=s@",   desc=>"Selects tests with given tag types (separate multiple tags with commas)";
def_option "noselect=s@", desc=>"De-Selects tests with given tag types (separate multiple tags with commas)";
def_option "list",        desc=>"List availabe tests in testlist (honors -select option)";
def_option "pre_tcl=s@",  desc=>"TCL commands to be executed prior to simulation 'run' command";
def_option "post_tcl=s@", desc=>"TCL commands to be executed after simulation 'run' command";

def_option_group("Control Options");
def_option "X",           desc=>"Show commands to issue, but do not execute them";
def_option "D",           desc=>"Display debug info while executing";
def_option "root",        desc=>"Define and mark current directory as root of work area (for non-Perforce use)";
def_option "quiet",       desc=>"Minimize display to stdout",
                          alias=>"q";
def_option "noq",         desc=>"Disables -quiet or -q",
                          alias=>"noquiet";
def_option "nouseropts",  desc=>"Skips use of user options file (user.xopts)";
def_option "dg",          desc=>"Disable Grafting", precmd=>"&disable_grafting";
def_option "show",        desc=>"Show control files and variables controlling build/run process";
def_option "postsim=s",   desc=>"Script to perform post processing",
                          default=>"postsim.pl";
def_option "xxx=s",       desc=>"For test purposes only",
                          precmd=>"&main::test_sub <VAL>", hidden=>1;
def_option "global_opts=s",
                          desc=>"Script used to define global options",
                          default=>"global_opts.pl";
def_option "wave_script",
                          desc=>"Script to use to control wavefile generation",
                          default=>"wavegen.pl";
def_option "report_script",
                          desc=>"Script to use to generate sim report",
                          default=>"sim_report.pl";
def_option "chase_script",
                          desc=>"Script to use to search srclists",
                          default=>"chase_files.pl";
def_option "logviewer=s", 
                          desc=>"Defines utility used to view log files",
                          default=>"less";
def_option "shell_script=s",
                          desc=>"Script used to generate basic cfg/ shell structure",
                          default=>"gen_shell.pl";
def_option "noabort",     desc=>"Do not terminate execution on script abort";

def_option_group("Post Processing Options");
def_option "vl",          desc=>"View log file for referenced test";
def_option "vw",          desc=>"View wave file for referenced test";
def_option "parse_log",   desc=>"Parse log file, report results";
def_option "ls",          desc=>"Display test directory for referenced test";
def_option "show_post",   desc=>"Display postsim.log for referenced test";
def_option "probefile=s", desc=>"Specify svcf probes file for Simvision", default=>"simvision",
                          alias=>"pf";
def_option "probedir=s@", desc=>"Directory of SimVision probe files";
def_option "use_mwa",     desc=>"Search for other components in Master Work Area (MWA)",
                          alias=>"mwa";
def_option "no_mwa",      desc=>"Disable -use_mwa option",
                          alias=>"nomwa";
def_option "skip_mwa=s@", desc=>["Skip given sibling directory(s) when using Master Work Area",
                                 "Separate directories with commas"];
def_option "mcs",         desc=>"Use Master Work Area Client Spec";
def_option "run_all=s",   desc=>["Run gosim in all sibling work areas.",
                                 "using given command line options (e.g. -t all -grid)"];
def_option "sync",        desc=>["Sync all sibling work areas before execution",
                                 "Only used with -run_all option"];

def_option_group("Test specific options");
def_option("name=s",      desc=>"Test name (OVM_TESTNAME)");
def_option("rand",        desc=>"Generate random seed, feed to simulation");
def_option("seed=n",      desc=>"Run sim with given random seed (decimal value only)");
def_option("error=s@",    desc=>"Regular expression defining log error string");
def_option("ok_error=s@", desc=>"Regular expression defining log error to ignore");
def_option("reqd=s@",     desc=>"Regular expression defining log string required to PASS sim");
def_option "tag=s@",      desc=>"Tag test with given type.  Used for test selection";
def_option "datafile=s@", desc=>"Datafile to link to from test execution directory";

#$xt->merge($xm);# duplicate options object for test-specific options

my $gen_shell = option_value("shell_script");
$gen_shell = `which $gen_shell`;
chomp $gen_shell;
exec_perl_file($gen_shell) if -x $gen_shell;

$xm->GetXopts(\@ARGV);# initial command-line processing

use_option("-rand") if option_given("loops");
$quiet = option_given("quiet");
$quiet = 1 if option_given("list");

my $use_mcs;
run("touch .gosim") if option_given("root");
get_client(\%client);# Perforce clientspec - defines work area, branch and GCO
$use_mcs = 1 if exists $client{MCS};
# $ENV{GCO_LOCAL} now contains current baseline in GCO for local unit
my $user_opts = undef;
if (-d $client{Root} && $client{Root} =~ /^\/.+\/.+/) {
  chdir $client{Root};# goto root of work area
  unless (option_given("nouseropts")) {
    $user_opts = get_file("user.xopts");
    $user_opts = get_file("../user.xopts") unless defined $user_opts;
    if (defined $user_opts) {
      def_option_group("User defined options");
      exec_perl_file($user_opts);
    }
  }
  $use_mcs = 1 if option_given("mcs");;
  if (defined $use_mcs) {
    print "Using Master Client Spec $client{Client}\n";
    chdir $client{Prior_cwd};
    $client{Root} = $client{Prior_cwd};
  }
} else {
  show_help();
  abort("Cannot find client root: $client{Root} - aborting");
}
$cwd = get_cwd();
$ENV{GCO_LOCAL} = $cwd;
print "Executing from $cwd...\n";

my $global_opts = option_value("global_opts");
$global_opts = `which $global_opts`;
chomp $global_opts;
exec_perl_file($global_opts) if -x $global_opts;

my $setup_opts;
my $build_src;
my $build_script;
my $wavegen;
my $report_script;
my $chase_script;

unless (option_given("gen_shell")) {
  $setup_opts = get_file_abort("cfg/xopts/setup.xopts");
  exec_perl_file($setup_opts);

  $build_src = "cfg/xopts/build_model.pl";
  $build_script = get_file_abort($build_src);
  exec_perl_file($build_script);

  $wavegen = option_value("wave_script");
  $wavegen = `which $wavegen`;
  chomp $wavegen;
  exec_perl_file($wavegen) if -x $wavegen;

  $report_script = option_value("report_script");
  $report_script = `which $report_script`;
  chomp $report_script;
  exec_perl_file($report_script) if -x $report_script;

  $chase_script = option_value("chase_script");
  $chase_script = `which $chase_script`;
  chomp $chase_script;
  exec_perl_file($chase_script) if -x $chase_script;
}


#$xm->set_debug(1) ;
$xm->GetXopts(\@ARGV);# now process again with all externally defined options
help();

$quiet = option_given("quiet");
$debug = option_given("debug");
$debug = 1 if option_given("D");
if (defined $debug) {
  $xm->set_debug(1) ;
  $xt->set_debug(1);
  $quiet = undef 
}
$quiet = undef if option_given("noq");
my $noabort = 0;
my $X = option_given("X");
if (option_given("noabort") || defined $X) {
  $noabort = 1;
  Misc::SimUtil::noabort();
}
my $logfile = "nc.log";
my $waveopt = "";
my $viewonly = 0;
my $waveviewer = "simvision";
my $logviewer = option_value("logviewer");
my $dvt_vlog_files = ".dvt/.vlog_top_files";
$viewonly = 1 if option_given("vl");
$viewonly = 1 if option_given("vw");
$viewonly = 1 if option_given("show");
$viewonly = 1 if option_given("parse_log");
$viewonly = 1 if option_given("ls");
$viewonly = 1 if option_given("show_post");

# Initialize global control variables
$gbl->{BUILDOPTS} = $gbl->{GBL_BUILDOPTS};
$gbl->{WORK} = $cwd;
$gbl->{MODEL} = "$cwd/output";
$gbl->{SRCLISTS} = "cfg/srclists";
$gbl->{QOPTIONS} = "";
$gbl->{FINAL_SRCLIST} = "final.srclist";
$gbl->{ALTERA_SRCLIST} = "final_altera.qip";
$gbl->{ALTERA_P1B_SRCLIST} = "final_p1b_altera.qip";
$gbl->{RTL_SRCLIST} = "final_rtl.srclist";

# for backward compatibility
foreach my $k (keys %$gbl) {
  $gblvar{$k} = $gbl->{$k};
}

$xm->ExecXopts("precmd");
exit $gbl->{EXIT} if exists $gbl->{EXIT};

$gbl->{MODEL} = option_value("build_dir") if option_given("build_dir");
if (scalar @ARGV) {
  my $cmdline = join ' ', @ARGV;# unclaimed command line arguments
  print "Invalid options: $cmdline\n";
  exit 1;
}
my $last_jobid = -1;
my $wait4build = "";
my $qcmd = "";
$qcmd = "qrun" if option_given("grid");
$qcmd .= "qrun -i" if option_given("igrid");

$testname = undef;
my $list_count = 0;
if (option_given("list")) {
  $testname = "all";
} else {
  $testname = $gbl->{DEFAULT_TEST} if exists $gbl->{DEFAULT_TEST};
  $testname = option_value("t") if option_given("t");
  $testname = option_value("xt") if option_given("xt");
}
if (defined $testname && $testname =~ /(.+)__(\w+)$/) {
  $testname = $1;
  use_option "-seed $2";
}
my $testmatch = undef;
$testmatch = option_value("tm");
$ENV{TESTNAME} = $testname;
my $recompile = option_value("recompile");
my $compile_dir = $gbl->{MODEL};
$compile_dir = "output" if defined $recompile;

my $auto_select = 0;
my $auto_deselect = 0;
my %auto_tags;
my %select_tags;
my %noselect_tags;
my $use_select_tags = 0;
if (option_given("select")) {
  my $tags = option_value("select");
  foreach (@$tags) {
    my @t = split /,/;
    foreach (@t) {
      $select_tags{$_} = 1;
    }
  }
  $use_select_tags = scalar keys %select_tags;
}
if (option_given("noselect")) {
  my $tags = option_value("noselect");
  foreach (@$tags) {
    my @t = split /,/;
    foreach (@t) {
      $noselect_tags{$_} = 1;
    }
  }
}

# Construct build options
$gbl->{MODEL} .= "/" . $gbl->{RESULTS} if exists $gbl->{RESULTS};
$gbl->{BUILDOPTS} .= " -nclibdirname $compile_dir" unless defined $recompile;
$gbl->{BUILDOPTS} .= " -top " . option_value("top") if option_given("top");
$gbl->{BUILDOPTS} .= " -nostdout" if $qcmd eq "qrun";
$gbl->{BUILDOPTS} .= " -access +rwc" unless $xt->option_given("nodebug");
$gbl->{BUILDOPTS} .= " -l $gbl->{MODEL}/nc.log" unless defined $recompile;
$gbl->{BUILDOPTS} .= " -c" if defined $recompile && option_given("S");
$gbl->{BUILDOPTS} .= " -q" if defined $quiet;
my $em = 3;
$em = option_value("errormax") if option_given("errormax");
$gbl->{BUILDOPTS} .= " -errormax $em";
if (option_given("ovm")) {
  $gbl->{BUILDOPTS} .= " -ovm -define USE_CADENCE_OVM_PKG";
} elsif (!option_given("ovmhome")) {
  $gbl->{BUILDOPTS} .= " -ovmnoautocompile";
}
my $rbopts = option_value("rbopts");# run/build opts

my $batch = "tests";
$batch = $gbl->{BATCH} if exists $gbl->{BATCH};
$gbl->{BATCHDIR} = "$gbl->{MODEL}/$batch";

$xm->ExecXopts("cmd");
exit $gbl->{EXIT} if exists $gbl->{EXIT};

if (option_given("show")) {
  print "  Setup script: $setup_opts\n";
  print "  Build script: $build_script\n";
  print "Wave gen script: $wavegen\n";
  print "  Report script: $report_script\n";
  print "  Shell script: $gen_shell\n";
  print "  User options: $user_opts\n";
  $xm->dumpvars();
  $xm->show_given_options();
  exit 0;
}

run_abort("rm -fr $gbl->{MODEL}") if option_given("clean");
run_abort("mkdir -p $gbl->{MODEL}") unless -e $gbl->{MODEL};
run_abort("mkdir -p $gbl->{BATCHDIR}") unless -e "$gbl->{BATCHDIR}";

check_mwa();

$xm->ExecXopts("postcmd");
$xm->dumpvars() if defined $debug;
exit $gbl->{EXIT} if exists $gbl->{EXIT};

run_all() if option_given("run_all");

if (option_given("ovmhome")) {
  if (exists $ENV{GCO_OVM}) {
    $gbl->{BUILDOPTS} .= " -ovmhome $ENV{GCO_OVM}";
  }
}

unless (option_given("C") || $viewonly == 1 || option_given("list")) {
  print "\nBuilding model...\n" unless defined $quiet;
  my $buildopts = option_value("buildopts");
  $gbl->{BUILDOPTS} .= " " . join(' ', @$buildopts) if defined $buildopts;
  $gbl->{BUILDOPTS} .= " " . join(' ',@$rbopts) if defined $rbopts;
  eval { build_model() }; 
  if ($@) {
    print $@;
    die "Error: Invalid build_model() or $build_src script not found\n" 
  }
#    "-reflib rvl_lib -reflib xbus_pkg_lib",
}

unless (option_given("S") && !(defined $recompile)) {
  my $testlist;
  $testlist = $gbl->{DEFAULT_TESTLIST} if exists $gbl->{DEFAULT_TESTLIST};
  $testlist = option_value("tl") if option_given("tl");
  if (option_given("xt")) {
    add_test($testname);
  } else {
    print "Scanning for test \'$testname\'...\n" if defined $testname && defined $quiet;
    include($testlist);
  }
  if (option_given("list")) {
    print "Tests listed: $list_count\n";
  } else {
    print "No tests executed.  Test selection did not match\n" if ($execute_count == 0);
  }
  if ($execute_count > 1) {
    print "*** $execute_count tests submitted ***\n";
  }
}

# Execute given testlist, graft testlist file first
sub include {
  my $tl = shift;
  die "No testlist given\n" unless defined $tl;
  my $tl2 = get_file_abort($tl,paths=>["cfg/testlists"],suffix=>["tl"]);
  print "Executing testlist $tl ($tl2)\n" unless defined $quiet;
  exec_perl_file($tl2);
}

# Repeat tests for -loops option
if (option_given("loops")) {
  my $loops = option_value("loops");
  my $test;
  while ($loops-- > 1) {
    foreach $test (keys %testdb) {
      my @tl;
      foreach (@{$testdb{$test}}) {
        push @tl, $_;
      }
      execute_test($test, @tl);
    }
  }
}

exit 0;# normal exit

# Grafts given srclists, returns string with grafted srclists preceeded by -f
# Result string can be fed directly to irun command line
sub get_srclist {
  my @srclists = @_;
  my $final_srclist = "$gbl->{MODEL}/$gbl->{FINAL_SRCLIST}";
  if (uc($srclists[0]) eq "ALTERA") {
    shift @srclists;
    $final_srclist = "$gbl->{MODEL}/$gbl->{ALTERA_SRCLIST}";
  } elsif (uc($srclists[0]) eq "ALTERA_P1B") {
    shift @srclists;
    $final_srclist = "$gbl->{MODEL}/$gbl->{ALTERA_P1B_SRCLIST}";    
  } elsif (uc($srclists[0]) eq "RTL") {
    shift @srclists;
    $final_srclist = "$gbl->{MODEL}/$gbl->{RTL_SRCLIST}";
  }
  `rm -f $final_srclist`;
  my @final;
  foreach (@srclists) {
    my $f = graft_srclist($_,$gbl->{MODEL});
    `echo '# -f $f' >>$final_srclist`;
    `cat $f >>$final_srclist`;
    `echo >>$final_srclist`;
  }
  print `echo "-f $gbl->{MODEL}/final.srclist" > $dvt_vlog_files` if -e $dvt_vlog_files;
  return "-f $final_srclist";
}

# Called by testlist to define a single test
# Accepts multiple lines
# Will also execute test if selected
sub add_test {
  my @test_lines;
  foreach (@_) {
    push @test_lines, shellwords($_);
  }
  $_ = shift @test_lines;
  s/^\s*//; s/\s*$//;
  my ($test, @tail) = split; 
  unshift @test_lines, @tail if scalar @tail;
  print "Parsing test: $test @test_lines\n" if defined $debug;
  if (!defined $testname || uc($testname) eq "ALL" || $use_select_tags > 0 
    || (defined $testname && $test eq $testname && !defined $testmatch)
    || (defined $testmatch && $test =~ /$testmatch/)) {
    execute_test($test, @test_lines);
  }
}

# define tags to be assigned to all subsequent tests
# Called from testlist
sub add_tags {
  my @tags = @_;
  foreach (@tags) {
    $auto_tags{$_} = 1;
  }
  process_tags();
}

# remove selected tags
# Called from testlist
sub del_tags {
  my @tags = @_;
  foreach (@tags) {
    delete $auto_tags{$_};
  }
  process_tags();
}

sub process_tags {
  $auto_select = 0;
  $auto_deselect = 0;
  foreach (keys %auto_tags) {
    $auto_select = 1 if exists $select_tags{$_};
    $auto_deselect = 1 if exists $noselect_tags{$_};
  }
  $auto_select = 1 if exists $select_tags{all} || exists $select_tags{ALL};
}

# Executes given test
# Syntax: execute_test(testname,line1,line2,...);
# Will process options in testlines using $xt options object
sub execute_test {
  my ($test, @test_lines) = @_;
  my $seed = get_seed();
  my $orig_testline = join ' ', @test_lines;
  my @save_lines = @test_lines;
  my $testname = $test;
  print "Calling execute_test: $test\n" if defined $debug;
  $xt->clear();# clear test-specific options from last test
  $xt->copy($xm);# copy all global options
  $xt->GetXopts(\@test_lines);
  $xt->ExecXopts("precmd");
  $xt->ExecXopts("cmd");
  $xt->ExecXopts("postcmd");
  my $testline = join ' ', @test_lines;
  $testname = $xt->option_value("name") if $xt->option_given("name");

  my $tags = $xt->option_value("tag");
  if ($use_select_tags && $auto_select == 0) { # select only tests matching -select tags
    return unless defined $tags;
    my $found = 0;
    foreach (@$tags) {
      $found = 1 if exists $select_tags{$_};
    }
    return unless $found == 1;
  }
  if (scalar keys %noselect_tags) { # don't select tests matching -noselect tags
    return if $auto_deselect == 1;
    my $found = 0;
    foreach (@$tags) {
      $found = 1 if exists $noselect_tags{$_};
    }
    return if $found == 1;
  }

  unless (exists $testdb{$test}) { # remember tests run;
    $testdb{$test} = ();
    foreach (@save_lines) {
      push @{$testdb{$test}}, $_;
    }
  }
 
  # Construct run options
  $gbl->{RUNOPTS} = $gbl->{GBL_RUNOPTS};
  my $runopts = $xt->option_value("first_runopts");
  if (defined $runopts) {
    my @opts = reverse @$runopts;# last is first
    $gbl->{RUNOPTS} .= " " . join(' ', @opts); 
  }
  $runopts = $xt->option_value("runopts");
  $gbl->{RUNOPTS} .= " " . join(' ', @$runopts) if defined $runopts;
  $gbl->{RUNOPTS} .= " " . join(' ', @$rbopts) if defined $rbopts;
  $gbl->{RUNOPTS} .= " -nclibdirname $compile_dir";
  $gbl->{RUNOPTS} .= " -gui" if $xt->option_given("gui");
  #$gbl->{RUNOPTS} .= " -debug" unless $xt->option_given("nodebug");
#  $gbl->{RUNOPTS} .= " -access +rwc" unless $xt->option_given("nodebug");
  $gbl->{RUNOPTS} .= " -nostdout" if $qcmd eq "qrun";
  $gbl->{RUNOPTS} .= " -ovm" if option_given("ovm");
  $gbl->{RUNOPTS} .= " -q" if defined $quiet;
  if ($xt->option_given("verbosity")) {
    my $vopts = $xt->option_value("verbosity");
    my $verbo = shift @$vopts;
    $verbo = "OVM_$verbo" unless $verbo =~ /OVM_/;
    $gbl->{RUNOPTS} .= " +OVM_VERBOSITY=$verbo";
  }

  unless (defined $seed) { # cmd-line seeds take precedence
    $seed = gen_seed() if $xt->option_given("rand");
    $seed = $xt->option_value("seed") if $xt->option_given("seed");
  }
  my $testdir = "$gbl->{BATCHDIR}/$test";
  if (defined $seed) {
    $testdir .= "__$seed"; 
    $gbl->{RUNOPTS} .= " -svseed $seed";
  }
  $testdir = option_value("run_dir") if option_given("run_dir");
  return if exists $tests_run{$testdir};# don't let exact same test run again in one batch
  $tests_run{$testdir} = 1;
  $gbl->{TESTNAME} = $testname;
  $gbl->{TESTDIR} = $testdir;
  if ($viewonly == 1) {
    if (option_given("vl")) {
      launch("$logviewer $testdir/nc.log");
    } elsif (option_given("vw")) {
      my $cmd = $waveviewer;
      my $probefile = $xm->option_value("probefile");
      if (defined $probefile) {
        my $dirs = option_value("probedir");
        push @$dirs, "." unless defined $dirs;
        my $pf = get_file($probefile, paths=>$dirs, suffix=>["svcf"]);
        $cmd .= " -input $pf" if defined $pf && -e $pf;
      }
      #$cmd .= " $testdir/waves.shm";
      $cmd .= " " . get_wavedir();
      launch($cmd);
    } elsif (option_given("parse_log")) {
      chdir $testdir;
      build_postsim($logfile);
      run("./gosim.post 0");
    } elsif (option_given("ls")) {
      chdir $testdir;
      run("ls -l");
      print "$testdir\n";
    } elsif (option_given("show_post")) {
      chdir $testdir;
      run("cat postsim.log");
    }
    exit 0;
  } else {
    if (option_given("list")) {
      print "$test $orig_testline\n";
      $list_count++;
    } else {
      unless (defined $quiet) {
        print "\n\nExecuting test: $testdir...\n";
        print "testline: $orig_testline\n";
      }
      do_execute_test($test, $testname, $testdir, $testline);
    }
  }
  chdir $cwd;# go back to root directory
}

# Execute given test, re-run if fails an -rerun given
sub do_execute_test {
  my ($test, $testname, $testdir, $testline, $iteration) = @_;
  my $save_opts = $gbl->{RUNOPTS};
  run("mkdir -p $testdir") unless -e $testdir;
  run("rm -rf $testdir/*");
  if (-d $testdir || defined $X) {
    chdir $testdir;
    $gbl->{RUNOPTS} .= " +OVM_TESTNAME=$testname " . $testline;
    $gbl->{LOGFILE} = $logfile;
    $gbl->{RUNOPTS} .= " -l $logfile";
    if ($xt->option_given("datafile")) {
      my $datafiles = $xt->option_value("datafile");
      foreach my $f (@$datafiles) {
        $f = "$gbl->{WORK}/$f" unless $f =~ /^\//;
        run("ln -s $f");
      }
    }
    eval { $waveopt = genwave() };
    $gbl->{RUNOPTS} .= " -input $waveopt" if $xt->option_given("wave");
    if ($@) {
      my $f = option_value("wave_script");
      die "Error: Invalid genwave() routine defined or $f not found\n";
    }
    gentcl($waveopt);
    $abort_ok = 0;
    build_postsim($logfile);
    eval { run_test(); };
    if ($@) {
      print $@;
      print "Error: Invalid run_test() or $build_src script not found\n";
      exit ;
    }
    unless ($qcmd eq "qrun") {
      print "Test results for \'$test\' ($testname)\n";
      print "         $testdir/nc.log\n";
      runq("./gosim.post $exit_value");
      unless (-e "$testdir/postsim.pass") { 
        # Test failed, rerun if requested
        my $rerun = option_given("rerun");
        if (defined $iteration || !defined $rerun) {
          abort ("*** Simulation Failed ***") 
        } else {
          my @options = shellwords("-wave");
          $xt->GetXopts(\@options);
          $gbl->{RUNOPTS} = $save_opts;# remove test-specific options
          print "\nRe-execute failed test with wave file enabled\n";
          do_execute_test($test,$testname,$testdir,$testline,1);
        }
      }
    }
    $abort_ok = 1;
    $execute_count++;
  } else {
    abort("Could not find test directory: $testdir");
  }
}

# Check for Master Work Area, update env variables as specified
sub check_mwa {
  return unless (option_given("use_mwa") || defined $use_mcs) && !option_given("no_mwa");
  my %skip_dirs;
  if (option_given("skip_mwa")) {
    my $skips = option_value("skip_mwa");
    foreach my $arg (@$skips) {
      foreach (split(/,/,$arg)) {
        $skip_dirs{$_} = 1;
      }
    }
  }
  my ($tail, $base) = fileparse($cwd);
  chdir "..";
  my $mwa = get_cwd();
  print "Checking for sibling work areas in $mwa...\n";
  opendir my $dh, ".";
  my @ldirs = readdir $dh;
  foreach my $dir (@ldirs) {
    next unless -d $dir;
    next if exists $skip_dirs{$dir};
    next if $dir =~ /^\./;
    next if $dir eq $tail;
    my $branch;
    if (defined $use_mcs) {
      my $tgt = "$dir/...";
      if (exists $client{View}{$tgt}) {
        $branch = $client{View}{$tgt};
        print "dir=$dir branch=$branch\n" if defined $debug;
        $branch =~ s/^\/\//\//;
        $mwa_branches{$branch} = "$mwa/$dir";
      }
    } else {
      my %p4client;
      chdir $dir;
      get_client(\%p4client, read_only=>1);# Perforce clientspec - defines work area, branch and GCO
      $branch = $p4client{Branch};
      if (defined $branch) {
        print "dir=$dir branch=$branch\n" if defined $debug;
        $branch =~ s/^\/\//\//;
        $mwa_branches{$branch} = "$mwa/$dir";
      }
    }
    chdir $mwa;
  }
  foreach my $var (keys %ENV) {
    if ($var =~ /^GCO_/) {
      next if $var =~ /^GCO_LOCAL$/;
      my $env = $ENV{$var};
      $mwa_dependents{$var} = $env;
      foreach my $b (keys %mwa_branches) {
        if ($env =~ /$b/) {
          print "Replacing $var ($ENV{$var}) with $mwa_branches{$b}\n";
          $ENV{$var} = $mwa_branches{$b};
          $mwa_dependents{$var} = $mwa_branches{$b};
        }
      }
    }
  }
  chdir $cwd;
}

# Builds and runs regression in all sibling work areas in Master Work Area
sub run_all {
  my $options = option_value("run_all");
  foreach my $branch (keys %mwa_branches) {
    my $dir = $mwa_branches{$branch};
    my %p4client;
    chdir $dir;
    get_client(\%p4client, read_only=>1);# Perforce clientspec - defines work area, branch and GCO
    my $client = $p4client{Client};
    my $cmd = "p4 -c $client sync";
    run($cmd);
    $cmd = "gosim $options";
    run($cmd);
  }
  exit 0;
}

# Generate TCL file for final sim execution
sub gentcl {
  my ($wave) = @_;
  my $tcl = "$gbl->{TESTDIR}/run.tcl";
  my $fh;
  if (open $fh, ">", $tcl) {
    if (defined $wave) {
      print $fh "if { [info exists env(GOSIM_WAVES)] } {\n";
      print $fh "  source $wave\n";
      print $fh "}\n";
    }
    unless (option_given("gui")) {
      if (option_given("pre_tcl")) {
        my $tcl = option_value("pre_tcl");
        foreach (@$tcl) {
          print $fh "$_\n";
        }
      }
      my $run_args = "";
      $run_args = option_value("run_args") if option_given("run_args");
      print $fh "run $run_args\n";
      if (option_given("post_tcl")) {
        my $tcl = option_value("post_tcl");
        foreach (@$tcl) {
          print $fh "$_\n";
        }
      }
      print $fh "finish 2\n";
    }
  }
  close $fh;
  print "Generated TCL file: $tcl\n" if defined $debug;
  $gbl->{RUNOPTS} .= " -input run.tcl";
}

# Creates script to execute postsim processing
sub build_postsim {
  my ($logfile) = @_;
  my $fh;
  my $script = "gosim.post";
  my $cmd = option_value("postsim") . " -exit \$x";
  my @errors = ();
  my @ok_errors = ();
  my @reqd = ();
  if ($xt->option_given("error")) {
    my $err = $xt->option_value("error");
    push @errors, @$err;
  }
  if ($xt->option_given("ok_error")) {
    my $ok = $xt->option_value("ok_error");
    push @ok_errors, @$ok;
  }
  if ($xt->option_given("reqd")) {
    my $rq = $xt->option_value("reqd");
    push @reqd, @$rq;
  }
  foreach (@errors) {
    $cmd .= " -error \'$_\'";
  }
  foreach (@ok_errors) {
    $cmd .= " -ok_error \'$_\'";
  }
  foreach (@reqd) {
    $cmd .= " -reqd \'$_\'";
  }
  $cmd .= " $logfile";
  open $fh, ">", $script || die "Cannot write $script\n";
  print $fh "#!/bin/csh -f\n";
  print $fh "set x = \$1\n";# exit value
  print $fh "echo Simulation exit value: \$x\n";
  print $fh "$cmd\n";
  print $fh "set y = \$?\n";# exit value
  print $fh "exit \$y\n";
  close $fh;
  runq("chmod +x $script");
}

# Calls irun with standard usage for sim model build
# Accepts any number of options which are passed to irun
# Requires at least -f options for srclists
sub std_build {
  my (@opts) = @_;
  qbuild("irun -c",
    @opts,
    $gbl->{BUILDOPTS},
  );
}

# Calls irun with standard usage for sim execution
# Pass additional options which are added to irun
sub std_run {
  my (@opts) = @_;
  my $cmd = "irun";
  $cmd .= " -R" unless defined $recompile;
  qrun($cmd,
    @opts,
    $gbl->{RUNOPTS},
  );
}

# get random seed, if any requested
sub get_seed {
  my $seed = undef;
  if (option_given("seed")) {
    $seed = option_value("seed");
  } elsif (option_given("rand")) {
    $seed = gen_seed();
  }
  return $seed;
}

# Returns string with generated random seed
sub gen_seed {
  my $seed = int rand(0x7fffffff);
  return $seed;
}

# Execute given file as perl, abort if error detected
sub exec_perl_file {
  my $file = shift;
  my $return;
  print "Executing perl file \'$file\'...\n" if defined $debug;
  unless ($return = do $file) {
    die "Couldn't parse $file: $@" if $@;
    #die "Couldn't execute $file: $!" unless defined $return;
    #die "Couldn't execute $file" unless $return;
  }
}

# Issue build command, optionally using SunGrid
sub qbuild {
  my $cmd = my_join(@_);
  my $ch;
  my $qopts = "-name gosim.build -q -out $gbl->{MODEL}/q.log -script $gbl->{MODEL}/gosim.build";
  $qopts = "" if $qcmd eq "";
  $last_jobid = -1;
  if ($qcmd eq "qrun") {
    print "qrun $qopts $cmd\n" unless defined $quiet;
    if (open $ch, "qrun $qopts $cmd|") {
      while (<$ch>) {
        $last_jobid = $1 if /^Your job (\d+)/;
        print ;
      }
    }
    close $ch;
    # First sim job must wait until build completes
    $wait4build = "-wait4 $last_jobid" if $last_jobid >= 0;
  } else {
    run_abort("$qcmd $qopts $cmd", echo=>1);
  }
}

# Issue run command, optionally using SunGrid
# Jobs will hold until build job completes.
sub qrun {
  my $cmd = my_join(@_);
  my $script = "$gbl->{TESTDIR}/gosim.run";
  if ($qcmd eq "") {
    open my $fh, ">$script" || die "Cannot create file: $script\n";
    print $fh "#!/bin/csh -f\n";
    print $fh "$cmd\n";
    close $fh;
    `chmod +x $script`;
    print "Executing: $script\n";
    print "$cmd\n";
    if (option_given("gui")) {
      launch($script);
    } else {
      run_abort($script, echo=>1);
    }
  } else {
    my $qopts = "-name gosim.run -q -out $gbl->{TESTDIR}/q.log -script $script";
    $qopts .= " $gbl->{QOPTIONS}";
    $qopts .= " -queue sj02.q" if option_given("grid");
    $qopts .= " -post \'.\/gosim.post \$x\'" if $qcmd eq "qrun";
    $qopts .= " -rerun \'setenv GOSIM_WAVES\'" if option_given("rerun");
    $qopts = "" if $qcmd eq "";
    run_abort("$qcmd $qopts $wait4build $cmd", echo=>1);
  }
}

# Join elements of array, separated by spaces.
# Ignores undefined elements
sub my_join {
  my (@args) = @_;
  my $cmd = "";
  foreach (@args) {
    $cmd .= "$_ " if defined $_;
  }
  return $cmd;
}

# Execute command in background and exit script
sub launch {
  fork and exit;
  setpgrp 0, 0;
  run(@_);
  exit 0;
}

sub run {
  my $cmd = "";
  foreach (@_) {
    $cmd .= "$_ ";
  }
  $cmd =~ s/^\s*//;
  print "$cmd\n" unless defined $quiet;
  system $cmd unless defined $X;
  $exit_value = $? >> 8;
}

# Submit given command to shell
# Options: echo=>1 to force echo
sub run_abort {
  my ($cmd, %args) = @_;
  $cmd =~ s/^\s*//;
  print "$cmd\n" unless defined $quiet && !exists $args{echo};
  system $cmd unless defined $X;
  $exit_value = $? >> 8;
  if ($exit_value > 0 && $abort_ok == 1 && $noabort == 0) {
    abort "Error $exit_value returned from systemcall";
  }
}

# Always run these commands 'quietly'
sub runq {
  my $q = $quiet;
  $quiet = 1;
  run(@_);
  $quiet = $q;
}

sub test_sub {
  my $arg = shift;
  print ">>>test_sub: $arg<<<\n";
}

sub help {
  return unless option_given("help");
  print<<EOF_MAIN;
  Simulation Build Flow

  Syntax: gosim [options]

  See Wiki for additional details on using gosim.
EOF_MAIN
  show_help();
  print "\nAll options unused by gosim are passed on through to 'irun' - for both build and run\n";
  exit 0;
}
