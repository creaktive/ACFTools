#!/usr/bin/perl -w

#    This file is part of ACFTools X-Plane aircraft data exporter/importer
#    Copyright (C) 2004  Stanislaw Y. Pusep
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
#    E-Mail:    stas@sysd.org
#    Site:      http://xplane.sysd.org/

package XPlane::Convert::AC3Dparse;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA		= qw(Exporter);
@EXPORT		= qw(AC3Dparse ACForder);


sub AC3Dparse {
   my $ac3 = shift;
   local $_;

   open (AC3D, $ac3) || die "Can't open $ac3: $!\n";
   $_ = scalar <AC3D>;
   die "Unknown AC3D file format!\n" unless /^AC3Db/i;

   my @ac3d = ();
   while (<AC3D>) {
      chomp;
      s/\s+$//;
      next unless $_;
      push @ac3d, $_;
   }
   close AC3D;

   my $count = 0;
   my %header = ();
   foreach (@ac3d) {
      if (/^\d/) {
         last;
      } elsif (/^([a-z]+)\s+(.+)$/i) {
         $header{$1} = $2;
      }

      $count++;
   }

   my $kids = &check (kids => \%header);
   if ($kids != 1) {
      die "Can only import one object per AC3D file!\n" .
          "Please delete objects you do not need to merge or put them into separate files.\n";
   }
   my $name =  &check (name => \%header);
   $name =~ s/^"//;
   $name =~ s/"$//;
   my $numvert = &check (numvert => \%header);

   my @loc = ();
   if (defined $header{loc}) {
      @loc = split /\s+/, $header{loc};
      die "Broken AC3D format with non-3D coordinate ;)\n" if @loc != 3;
   }

   my @ver = ();
   for (my $i = 0; $i < $numvert; $i++) {
      $_ = $ac3d[$count++];
      chomp;
      s/\s+$//;
      my @v = split /\s+/, $_;
      die "Vertex #$i doesn't looks good!\n" unless @v == 3;
      push @ver, [@v];
   }
   die "$ac3 seems to be broken!\n" if scalar @ver != $numvert;

   return ($name, [@ver], [@loc]);
}

sub ACForder {
   my ($verps, $ver) = @_;
   my $numvert = scalar @{$ver};
   die "AC3D file can't be ordered in $verps-vertex sections!\n" if $numvert % $verps;

   my @sort = ();
   my (@max, @min);
   for (my $i = 0; $i < $numvert / $verps; $i++) {
      my %sort = ();
      my @sect = splice @{$ver}, 0, $verps;

      @max = qw(0 0 0);
      @min = qw(0 0 0);
      my ($xs, $ys) = qw(0 0);
      foreach my $v (@sect) {
         $xs += abs ($$v[0]);
         $ys += abs ($$v[1]);
         &centre ($v, \@min, \@max);
      }
      my $xo = $min[0] + (($max[0] - $min[0]) / 2);
      my $yo = $min[1] + (($max[1] - $min[1]) / 2);

      if ($xs == 0) {
         foreach my $v (sort { $$a[0] <=> $$b[0] } @sect) {
            push @sort, $v;
         }
      } elsif ($ys == 0) {
         foreach my $v (sort { $$a[1] <=> $$b[1] } @sect) {
            push @sort, $v;
         }
      } else {
         foreach my $v (@sect) {
            my ($x, $y) = @$v;
            $x -= $xo;
            $y -= $yo;
            my $d = sqrt ($x**2 + $y**2);
            my $a = $d ? $y / $d : 0;
            $a = -$a - 2 if $x > 0;
            $a /= 10;

            while (defined $sort{$a}) {
               $a .= '0';
            }
            $sort{$a} = $v;
         }
         my @order = sort { $a <=> $b } keys %sort;
         if ($order[0] == $order[1]) {
            push @order, shift @order;
         } elsif ($order[-1] == $order[-2]) {
            unshift @order, pop @order;
         }

         foreach my $a (@order) {
#            printf STDERR "%.5f\t{ %.5f, %.5f, %.5f }\n", $a, @{$sort{$a}};
            push @sort, $sort{$a};
         }
#         print STDERR "\n";
      }
   }

   return [@sort];
}

sub centre {
   my ($ver, $min, $max) = @_;
   for (my $i = 0; $i < @$ver; $i++) {
      if (!$$max[$i] || $$ver[$i] > $$max[$i]) {
         $$max[$i] = $$ver[$i];
      } elsif (!$$min[$i] || $$ver[$i] < $$min[$i]) {
         $$min[$i] = $$ver[$i];
      }
   }
   return;
}

sub check {
   my ($var, $header) = @_;
   die "AC3D attribute '$var' undefined!\n" unless defined ${$header} {$var};
   return ${$header} {$var};
}

1;
