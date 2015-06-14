#!/usr/bin/perl
# Displays either available models or available release
use Getopt::Std;

sub usage {
print <<EOF;
Displays available models or releases from socip1 archive.
Use with script that separately captures user responses.
Syntax: $0 -rmh [model] [release]
-m  : Prompt for models
-r  : Prompt for release
-h  : Display this help
EOF
exit;
}
usage unless getopts('rmh');

$rel_dir = "$ENV{'PROJECT_REL'}"; 
$rel_dir = "/proj/socip1/IP";

if (@ARGV) {
   $model = shift @ARGV 
} elsif ($opt_m) {
   get_sorted_directories($rel_dir,\@model_list);
   foreach (@model_list) {
      chomp;
      next if /^\./;
      printf "%32s\n", $_;
   }
   exit ;
}

$rel_dir .= "/$model/release/ALL";
if ( !(-r $rel_dir) ) {
  print "  ERROR >> unreadable directory: $rel_dir\n";
  print "           please make sure to run 'proj_swgrp <proj_name>+' command first.\n\n" ;
  exit 1;
}  

if (@ARGV) {
   $xc = shift @ARGV;
} elsif ($opt_r) {
   get_sorted_directories($rel_dir,\@release_list);
   foreach (@release_list) {
      next if /^\./;
      push(@udirlist,$_) if /^U/;
      push(@idirlist,$_) if /^I/;
      push(@qdirlist,$_) if /^Q/;
   }

   if (-e "$rel_dir/prod") {#if prod exists consider it as latest qual else latest QC as latest qual
       $lastqual = `/bin/ls -l $rel_dir/prod | awk -F">" '{print \$2}' | awk '{print \$1}'`;
       chomp $lastqual;
   } else {
       $lastqual = pop(@qdirlist);
   }

   if ( !defined($lastqual) || ($lastqual eq '') ) {
     print "  ERROR >> unable to identify the most recent QC name!\n" ;
     exit 1;
   }

   ($date,$time,$user,@junk1) = split('_',$lastqual);
   $qc_time = "$date"."$time";
   $qc_time =~ s/Q// if $qc_time =~ /^Q/ ;
   $qc_time =~ s/I// if $qc_time =~ /^I/ ;
   $qc_time =~ s/U// if $qc_time =~ /^U/ ;

   @latest_uc_ic = ();

   foreach $uc (@udirlist) {#consider only UCs later than latest qual
     next if( $uc !~ /_/ ) ;
     ($date,$time,$user,$junk1,$proj) = split('_',$uc);
      next if( !defined($date) || !defined($time) ) ;
     $uc_time = "$date"."$time";
     $uc_time =~ s/U//;
     push (@latest_uc_ic, $uc,) if ($uc_time >= $qc_time);
   }
   push (@latest_uc_ic, "");

   foreach $ic (@idirlist) {#consider only ICs later than latest qual
     next if( $ic !~ /_/ ) ;
     ($date,$time,$user,$junk1,$proj) = split('_',$ic);
      next if( !defined($date) || !defined($time) ) ;
     $ic_time = "$date"."$time";
     $ic_time =~ s/I//;
     push (@latest_uc_ic, $ic) if ($ic_time >= $qc_time);
   }
   push (@latest_uc_ic, "");

   foreach $uc_ic (@latest_uc_ic) {#print UCs and ICs later than latest qual
     print "      $uc_ic\n";
   }

   printf "      %-45s <- prod\n", $lastqual; #print prod

   if (-e "$rel_dir/current") {#print current if it exists
       $current = `/bin/ls -l $rel_dir/current | awk -F">" '{print \$2}' | awk '{print \$1}'`;
       chomp $current;
       printf "      %-45s <- current\n", $current;
   }

   if (-e "$rel_dir/current_gold") {#print current_gold if it exists
       $current_gold = `/bin/ls -l $rel_dir/current_gold | awk -F">" '{print \$2}' | awk '{print \$1}'`;
       chomp $current_gold;
       printf "      %-45s <- current_gold\n",$current_gold;
   }

   exit ;
}

# get_sorted_directories(dir_name,\@dir_list);
sub get_sorted_directories {
   my ($dir_name,$dir_list) = @_;
   local *DIR;

   opendir(DIR, $rel_dir);
   my @dir_list = readdir(DIR);
   closedir(DIR);
   @$dir_list = sort(@dir_list);
}

## _END_OF_CODE
