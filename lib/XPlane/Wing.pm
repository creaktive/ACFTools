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

package XPlane::Wing;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use Math::Trig;

use XPlane::Wing::Airfoil;
use XPlane::Surface;

@ISA		= qw(Exporter);
@EXPORT		= qw(wing);


sub wing {
   my %data = @_;

   $data{is_right} = 0 unless defined $data{is_right};

   my $file = $data{filehandle};
   my @incidence = @{$data{incidence}};
   my $elem = scalar @incidence;
   push @incidence, $incidence[-1];
   my ($fname, $root_fname, $tip_fname, @root_foil, @tip_foil);

   if (defined $data{foil}) {
      $data{root_foil} = $data{foil};
      $data{tip_foil} = $data{foil};
   }

#   ($root_fname, @root_foil) = (ref $data{root_foil} eq 'ARRAY') ? @{$data{root_foil}} : airfoil ($data{root_foil});
#   ($tip_fname, @tip_foil) = (ref $data{tip_foil} eq 'ARRAY') ? @{$data{tip_foil}} : airfoil ($data{tip_foil});
   ($root_fname, @root_foil) = &clonefoil ($data{root_foil});
   ($tip_fname, @tip_foil) = &clonefoil ($data{tip_foil});

   $fname = ($root_fname eq $tip_fname) ? $root_fname : "$root_fname/$tip_fname";

   if (defined $data{normalize} && $data{normalize} >= 2) {
      @root_foil = normalize ($data{normalize}, @root_foil);
      @tip_foil = normalize ($data{normalize}, @tip_foil);
   }

   die "Root & Tip foils doesn't has the same vertex number!\n" if scalar @root_foil != scalar @tip_foil;
   my @diff = ();
   for (my $i = 0; $i < @root_foil; $i++) {
      $diff[$i] = (${$root_foil[$i]}[1] - ${$tip_foil[$i]}[1]) / $elem;
   }

   my @sec = ();
   my $elemx = ($data{root} - $data{tip}) / $elem;
   my $elemz = $data{semilen} / $elem;
   my $x = $data{root};
   my $z = 0;

   my $ns = 0;

   my @foil = @root_foil;
   for (my $i = 0; $i <= $elem; $i++) {
      my $a = 0;
      my $b = $z;
      rotate (\$a, \$b, $data{sweep}) if $b;
      push @sec, wsec (
         $data{arm}, $data{is_right},
         $x, $a, $b,
         $incidence[$i],
         $data{dihed},
         @foil,
      );

      $x -= $elemx;
      $z += $elemz;
      for (my $j = 0; $j < @diff; $j++) {
         ${foil[$j]}[1] -= $diff[$j];
      }
   }

   my $nv = scalar @sec;
   print $file <<EOH
OBJECT poly
name "wing[$data{index}] // $fname"
loc 0 0 0
numvert $nv
EOH
   ;

   foreach my $ver (@sec) {
      print $file "@$ver\n";
   }

   my $nfv = scalar @root_foil;
   $ns += surface ($file, $elem + 1, $nfv, $data{is_right}, $data{material}, 2);
   closer ($file, $data{material}, $nv-$nfv..$nv-1);
   closer ($file, $data{material}, 0..$nfv-1);
   $ns += 2;

   print $file "kids 0\n";

   return ($nv, $ns);
}

sub wsec {
   my ($arm, $mirror, $size, $a, $b, $inc, $dih, @foil) = @_;
   local $_;
   my @wsec = ();
   for (my $i = 0; $i < @foil; $i++) {
      # define section
      my $x = ${$foil[$i]}[0];
      my $y = ${$foil[$i]}[1];
      my $z = $b;

      # rotate
      rotate (\$x, \$y, -$inc);

      # scale
      $x *= $size;
      $y *= $size;

      # sweep
      $x -= $a;

      # dihedral
      rotate (\$z, \$y, $dih);

      # axis
      my @ver = ();
      if ($mirror) {
         @ver = ($z, $y, $x);
      } else {
         @ver = (-$z, $y, $x);
      }

      # arm
      for (0..2) {
         $ver[$_] += $$arm[$_];
      }

      # save
      push @wsec, [@ver];
   }
   return @wsec;
}

sub rotate {
   my ($x, $y, $r) = @_;
   return if !$r || (!$$x && !$$y);
   my $d = sqrt ($$x**2 + $$y**2);
   my $a = acos ($$x / $d);
   $a *= -1 if $$y < 0;
   $a += deg2rad ($r);
   $$x = $d * cos ($a);
   $$y = $d * sin ($a);
   return;
}

sub closer {
   my ($file, $mat, @ver) = @_;
   print $file "SURF 0x30\n",
         "mat ", $mat, "\n",
         "refs ", scalar @ver, "\n";
   foreach my $ver (@ver) {
      print $file "$ver 0 0\n";
   }
   return;
}

sub clonefoil {
   my $foil = shift;
   if (ref $foil eq 'ARRAY') {
      my $fname = ${$foil}[0];
      my @foil = ();
      for (my $k = 1; $k < @$foil; $k++) {
         push @foil, [ @{${$foil}[$k]} ];
      }
      return ($fname, @foil);
   } else {
      return airfoil ($foil);
   }
}

1;
