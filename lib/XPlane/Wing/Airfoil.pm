#!/usr/bin/perl -w

#    This file is part of ACFTools X-Plane aircraft data exporter/importer
#    Copyright (C) 2003  Stanislaw Y. Pusep
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#    E-Mail:    stanis@linuxmail.org
#    Site:      http://sysdlabs.hypermart.net/

package XPlane::Wing::Airfoil;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use Math::Interpolate qw(robust_interpolate);

@ISA		= qw(Exporter);
@EXPORT		= qw(airfoil normalize);


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

sub normalize {
   my ($n, @foil) = @_;
   return () if not $n or not @foil;

   my ($min, $max);
   foreach my $v (@foil) {
      my $x = $$v[0];
      $min = $x if not defined $min or $x < $min;
      $max = $x if not defined $max or $x > $min;
   }
   my $len = $max - $min;
   my $step = $len / ($n - 1);

   my (@ax, @ay, @bx, @by);
   my $f = 0;
   for (my $i = 0; $i < @foil; $i++) {
      my ($x, $y, $z) = @{$foil[$i]};
      $x -= $min;
      if ($x == 0) {
         $f++;
         unshift @bx, $x;
         unshift @by, $y;
      }
      if ($f) {
         push @ax, $x;
         push @ay, $y;
      } else {
         unshift @bx, $x;
         unshift @by, $y;
      }
   }

   my @xs = ();
#   for (my $x = 0, my $i = 0; $i < $n; $i++, $x += $step) {
#      push @xs, $x;
#   }
   for (my $x = 0, my $i = 0; $i < $n; $i++, $x += $step) {
      push @xs, (($x**2) * $len);
   }

   my @anew = ();
#   for (my $x = $len, my $i = 0; $i < $n; $i++, $x -= $step) {
   foreach my $x (reverse @xs) {
      my ($y, $dy) = robust_interpolate ($x, \@bx, \@by);
      push @anew, [$x + $min, $y, 0];
   }

   my @bnew = ();
   foreach my $x (@xs) {
#   for (my $x = 0, my $i = 0; $i < $n; $i++, $x += $step) {
      my ($y, $dy) = robust_interpolate ($x, \@ax, \@ay);
      push @bnew, [$x + $min, $y, 0];
   }

   return (@anew, @bnew);
}

1;
