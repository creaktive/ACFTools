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

package XPlane::Convert::AC3Dgen;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use File::Basename;
use XPlane::GetFoil;
use XPlane::Surface;
use XPlane::Wing;
use XPlane::Wing::Airfoil;

@ISA		= qw(Exporter);
@EXPORT		= qw(AC3Dgen);


sub AC3Dgen {
   my ($plain, $ac3d, $normalize, $min, $max, @force) = @_;
   local $_;
   $min = 44 unless defined $min;
   $max = 66 unless defined $max;

   # X-Plane constants
   my $secnum = 20;
   my $versec = 18;
   my $vernum = $secnum * $versec;

   my @par = @force;
   my @arm = ();
   my @ver = ();
   my @wng = ();
   my @bcw = ();
   my @nbl = ();

   open (TXT, $plain) || die "Can't open $plain: $!\n";
   while (<TXT>) {
      chomp;
      s%\s+$%%;
      s%//.*$%%;
      next unless $_;

      my ($type, $lval, $rval) = split /\s+/, $_, 3;
      if ($lval =~ /_prop_dir\[(\d+)\]/) {
         $bcw[$1] = &clean ($rval);
      } elsif ($lval =~ /_num_blades\[(\d+)\]/) {
         $nbl[$1] = &clean ($rval);
      } elsif ($lval =~ /_part_eq\[(\d+)\]/) {
         my $part = $1;
         $rval =~ s/^.*\s//;
         push @par, $part if $rval && not grep $_ == $part, @par;
      } elsif ($lval =~ /_els\[(\d+)\]/) {
         wparm (\@wng, $1, '_elements', $rval);
      } elsif ($lval =~ /_Rafl0\[(\d+)\]/) {
         wparm (\@wng, $1, '_Rafl0', $rval);
      } elsif ($lval =~ /_Tafl0\[(\d+)\]/) {
         wparm (\@wng, $1, '_Tafl0', $rval);
      } elsif ($lval =~ /_arm\[(\d+)\]/) {
         my $part = $1;
         @{$arm[$part]} = &vert ($rval);
      } elsif ($lval =~ /_Croot\[(\d+)\]/) {
         wparm (\@wng, $1, 'root', $rval);
      } elsif ($lval =~ /_Ctip\[(\d+)\]/) {
         wparm (\@wng, $1, 'tip', $rval);
      } elsif ($lval =~ /_semilen_SEG\[(\d+)\]/) {
         wparm (\@wng, $1, 'semilen', $rval);
      } elsif ($lval =~ /_dihed1?\[(\d+)\]/) {
         wparm (\@wng, $1, 'dihed', $rval);
      } elsif ($lval =~ /_sweep1\[(\d+)\]/) {
         wparm (\@wng, $1, 'sweep', $rval);
      } elsif ($lval =~ /_(?:incidence|anginc)\[(\d+)\]\[(\d+)\]/) {
         my $ind = $1;
         my $inc = $2;
         ${${$wng[$ind]}{incidence}}[$inc] = &clean ($rval);
      } elsif ($lval =~ /_body\[(\d+)\]/) {
         my $part = $1;
         next unless grep $_ == $part, @par;
         my @v = &vert ($rval);

#         next if $v[0] == 0 && $v[1] == 0 && $v[2] == 0;

         push @{$ver[$part]}, [@v];
      } elsif ($lval =~ /_is_left\[(\d+)\]/) {
         wparm (\@wng, $1, 'is_left', $rval);
      }
   }
   close TXT;


   # pre-cache airfoils/wings
   my %foils = ();
   my %fails = ();
   my $chkfoil = sub {
      my $afl = shift;
      my $foil = getfoil ($afl);
      if ($foil) {
         unless (defined $foils{$foil}) {
            my @foil = airfoil ($foil);
            my $name = shift @foil;
            $foils{$foil} = [$name, normalize ($normalize, @foil)];
         }
      } else {
         $fails{$afl}++;
      }
      return $foil;
   };

   print STDERR "caching airfoils\n";
   my @wings = ();
   my $wingn = ($normalize < 2) ? 0 : scalar @wng;
   for (my $ind = 0; $ind < $wingn; $ind++) {
      my %wing = %{$wng[$ind]};
      next if not defined $wing{semilen} or not $wing{semilen};
      next unless grep $_ == $ind, @par;

      $wing{index} = $ind;

      die "Parser: incomplete incidence table\n" if @{$wing{incidence}} < $wing{_elements};
      splice @{$wing{incidence}}, $wing{_elements};
      delete $wing{_elements};

      $wing{root_foil} = &$chkfoil ($wing{_Rafl0});
      delete $wing{_Rafl0};
      $wing{tip_foil} = &$chkfoil ($wing{_Tafl0});
      delete $wing{_Tafl0};

      push @wings, { %wing };
   }


   if (%fails) {
      print STDERR "\n", '#'x78, "\n",
                   "No airfoil definitions found for:\n\n";
      foreach my $fail (sort { lc $a cmp lc $b} keys %fails) {
         printf STDERR "'%s'\n", $fail;
      }
      print STDERR "\nPlease describe them in 'airfoil.lst' file found in 'data' sub-directory.\n",
                   '#'x78, "\n";
      return;
   }


   open (AC3D, ">$ac3d") || die "Can't write to $ac3d: $!\n";
   print AC3D <<EOH
AC3Db
MATERIAL "ac3dmat1" rgb 1 1 1  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
MATERIAL "ac3dmat13" rgb 0.533333 0.533333 0.533333  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
MATERIAL "ac3dmat8" rgb 0.627451 0.752941 0.878431  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
OBJECT world
kids _DUNNO_
EOH
   ;


   my $nv = 0;
   my $ns = 0;
   my $np = 0;
   foreach my $wing (@wings) {
      my %wing = %{$wing};
      my $ind = $wing{index};

      $wing{arm}	= $arm[$ind];
      $wing{filehandle}	= \*AC3D;
      $wing{material}	= 0;

      if (defined $wing{is_left}) {
         $wing{is_right} = $wing{is_left} ? 0 : 1;
         delete $wing{is_left};
      } else {
         $wing{is_right} = $ind % 2;
      }

      # left vstab
      $wing{dihed} = 180 - $wing{dihed} if $ind == 18;

      # accounter
      my $gen = sub {
         my ($wnv, $wns) = wing (%wing);
         $nv += $wnv;
         $ns += $wns;
         $np ++;
      };

      # resolve cached foils
      printf STDERR "\twing[%d] => root '%s' & tip '%s'\n", $ind, basename ($wing{root_foil}), basename ($wing{tip_foil});
      $wing{root_foil} = $foils{$wing{root_foil}};
      $wing{tip_foil} = $foils{$wing{tip_foil}};

      if ($ind <= 7) {
         # handle propellers
         $wing{material} = 2;
         $wing{is_right} = $bcw[$ind] > 0 ? 1 : 0;
         for (my $i = 0; $i < @{$wing{incidence}}; $i++) {
            ${$wing{incidence}}[$i] -= 90;
         }
         for (my $i = 1, $wing{dihed} = 90; $wing{dihed} < 450; $i++, $wing{dihed} += 360 / $nbl[$ind]) {
            $wing{index} = "BLADE($ind,$i)";
            &$gen;
         }
      } else {
         # handle normal wings
         &$gen;
      }

#      if ($ind == 8 || $ind == 9) {
#         foreach my $key (sort keys %wing) {
#            my $val;
#            if (ref $wing{$key} eq 'ARRAY') {
#               $val = '[' . join (', ', @{$wing{$key}}) . ']';
#            } else {
#               $val = $wing{$key};
#            }
#            printf STDERR "%-16s=> %s,\n", $key, $val;
#         }
#      }
   }


   foreach my $part (@par) {
      unless (grep $_ == $part, @force) {
         next if ($part < $min or $part > $max);
      }

      my $nver = scalar @{$ver[$part]};
      $nv += $nver;
      $np++;

      my $loc;
      if (defined $arm[$part]) {
         $loc = join ' ', @{$arm[$part]};
      } else {
         $loc = "0 0 0";
      }

      print AC3D <<EOO
OBJECT poly
name "body[$part]"
loc $loc
numvert $nver
EOO
   ;

      foreach my $ver (@{$ver[$part]}) {
         print AC3D "@$ver\n";
      }

      $ns += surface (\*AC3D, $secnum, $versec, 1, 1);
      print AC3D "kids 0\n";
   }

   close AC3D;


   local @ARGV = ($ac3d);
   $^I = '~';
   while (<>) {
      s/_DUNNO_/$np/;
      print $_;
   }
   unlink "$ac3d~";


   return $nv, $ns, $np;
}

sub vert {
   local $_ = &clean (shift);
   s/.*{\s+//;
   s/\s+}.*//;
   my @v = split /\s*,\s*/, $_;
   die "Parser: broken vertex\n" unless @v == 3;
   return @v;
}

sub clean {
   local $_ = shift;
   s/^.*=\s*"?//;
   s/"?\s*$//;
   return $_;
}

sub wparm {
   my ($wng, $ind, $key, $val) = @_;
   ${${$wng}[$ind]}{$key} = &clean ($val);
   return;
}

1;
