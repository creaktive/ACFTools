#!/usr/bin/perl -w
package Airfoil;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA		= qw(Exporter);
@EXPORT		= qw(airfoil);


sub airfoil {
   my $file = shift;
   my ($name, @ver);
   local $_;
   open (FOIL, $file) || die "Can't open $file: $!\n";
   while (<FOIL>) {
      chomp;
      s/\s+$//;
      s/^\s+//;
      $name = $_ unless defined $name;
      s/[\(\)]//g;
      my @v = /^(\-?\d*\.?\d+)\s+(\-?\d*\.?\d+)$/;
      next unless @v == 2;
      next if $v[0] < 0.0 or $v[0] > 1.0;
      $v[0] -= 0.25;
      push @ver, [@v, 0];
   }
   close FOIL;
   return ($name, @ver);
}

1;
