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

use strict;
use XPlane::Wing;

open (WING, '>wings.ac') || die "Can't write file: $!\n";
print WING <<EOH
AC3Db
MATERIAL "ac3dmat1" rgb 1 1 1  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
MATERIAL "ac3dmat13" rgb 0.533333 0.533333 0.533333  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
OBJECT world
kids 4
EOH
;

my $foil = '../data/naca2412.dat';
my $norm = 25;
my %wing;
%wing = (
   filehandle	=> \*WING,
   foil		=> $foil,
   semilen	=> 6.66,
   root		=> 1.67,
   tip		=> 1.67,
   sweep	=> 21.5,
   dihed	=> 15.8,
   arm		=> [0, -1.67, -2.42],
   incidence	=> [qw(1.7 1.7 1.7 1.7 1.7 1.7 1.7 1.7 1.7 1.7)],
   material	=> 0,
   normalize	=> $norm,
);

$wing{index} = 8;
$wing{is_right} = 0;
wing (%wing);
$wing{index} = 9;
$wing{is_right} = 1;
wing (%wing);

%wing = (
   filehandle	=> \*WING,
   foil		=> $foil,
   semilen	=> 6.66,
   root		=> 1.67,
   tip		=> 1.67,
   sweep	=> -21.5,
   dihed	=> -15.8,
   arm		=> [0, 1.67, 2.42],
   incidence	=> [qw(2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0)],
   material	=> 0,
   normalize	=> $norm,
);

$wing{index} = 10;
$wing{is_right} = 0;
wing (%wing);
$wing{index} = 11;
$wing{is_right} = 1;
wing (%wing);

close WING;
print "done!\n";
<STDIN>;
exit;
