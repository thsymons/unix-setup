#!/usr/bin/perl

my $foo = TestDescendent->new();
$foo->main();

package TestBase;
sub new {   my $class = shift;
   return bless {}, $class;
}
sub tbSub{
   my ($self, $parm) = @_;
   print "\nTestBase: $parm\n";
}
1;

package TestDescendent;
use base 'TestBase';
sub main {
   my $self = shift;
   $self->mySub( 1 );
   $self->tbSub( 2 );
   $self->mySub( 3 );
}
sub mySub{
   my $self = shift;
   my $parm = shift;
   print "\nTester: $parm\n";
}
1;
