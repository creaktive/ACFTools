#!/usr/bin/perl -w
package GetFoil;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use File::Basename;
use File::Spec::Functions;

@ISA		= qw(Exporter);
@EXPORT		= qw(getfoil);

use constant DATA => 'data';
use constant SPEC => 'airfoil.lst';


sub getfoil {
   my $foil = shift;
   local $_;

   open (LIST, catfile (DATA, SPEC)) || die "Can't open airfoil map: $!\n";
   my %afl = ();
   while (<LIST>) {
      chomp;
      s/\#.*$//;
      s/\s+$//;
      s/^\s+//;
      next unless $_;

      my ($afl, $dat) = split /\t+/, $_;
      $afl{$afl} = $dat;
   }
   close LIST;

   if (defined $afl{$foil} && -f catfile (DATA, $afl{$foil})) {
      return catfile (DATA, $afl{$foil});
   } else {
      return '';
   }
}

1;
