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

package XPlane::Surface;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA		= qw(Exporter);
@EXPORT		= qw(surface);


sub surface {
   my ($file, $ns, $vps, $type, $mat, $opt) = @_;
   $mat = 0 unless defined $mat;

   my @srf = ();
   for (my $i = 0; $i < (($ns - 1) * $vps) - 1; $i++) {
      if (defined $type and $type) {
         push @srf, [$i + 1, $i + 0, $i + $vps];
         push @srf, [$i + $vps, $i + $vps + 1, $i + 1];
      } else {
         push @srf, [$i + 0, $i + 1, $i + $vps];
         push @srf, [$i + $vps + 1, $i + $vps, $i + 1];
      }
   }

   printf $file "numsurf %d\n", (scalar @srf) + (defined $opt ? $opt : 0);
   foreach my $tri (@srf) {
      my ($a, $b, $c) = @$tri;
      print $file <<EOS
SURF 0x10
mat $mat
refs 3
$a 0 0
$b 0 0
$c 0 0
EOS
      ;
   }

   return scalar @srf;
}

1;
