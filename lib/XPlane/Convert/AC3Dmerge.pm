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

package XPlane::Convert::AC3Dmerge;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use XPlane::Convert::AC3Dparse;

@ISA		= qw(Exporter);
@EXPORT		= qw(AC3Dmerge);


sub AC3Dmerge {
   my ($ac3, $txt, $noorder) = @_;
   local $_;

   my ($name, $ver, $arm) = AC3Dparse ($ac3);
   my $part;
   if ($name =~ /\[(\d+)\]/) {
      $part = $1;
   } else {
      die "Malformed object name (should be 'body[N]' where N is proper integer)\n";
   }
   my $numvert = scalar @{$ver};
   if ($numvert != 360) {
      print STDERR "Warning: I expect 360 vertices and $ac3 has $numvert\n";
   }
   $name = quotemeta $name;

   $ver = ACForder (18, $ver) unless $noorder;

   local @ARGV = ($txt);
   $^I = '.bak';
   my $line;
   my $dfct = 0;
   my ($nv, $nl) = qw(0 0);
   while (<>) {
      $line = $_;

      chomp;
      s%\s+$%%;
      s%//.*$%%;
      next unless $_;

      my ($type, $lval, $rval) = split /\s+/, $_, 3;
      my $start = "$type\t$lval\t= ";
      if ($lval =~ /$name/) {
         if (@{$ver}) {
            $line = $start . '{ ' . join (', ', @{shift @{$ver}}) . " }\n";
            $nv++;
         } else {
            $line = $start . '{ 0, 0, 0 }' . "\n";
            $dfct++;
         }
      } elsif (@{$arm} == 3 && $lval =~ /_arm\[$part\]$/) {
         $line = $start . '{ ' . join (', ', @{$arm}) . "}\n";
      }
   } continue {
      print $line;
      $nl++;
   }

   if ($dfct) {
      printf STDERR "Import warning: %d vertex deficit!\n", $dfct;
   } elsif (@{$ver}) {
      printf STDERR "Import warning: %d vertex exceeded!\n", scalar @{$ver};
   }

   return ($nv, $nl);
}

1;
