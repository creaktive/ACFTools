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

use strict;
use XPlane::Wing::Airfoil;

my ($name, @ver) = airfoil ($ARGV[0]);
@ver = normalize ($ARGV[1], @ver) if defined $ARGV[1];
my $numvert = scalar @ver;


print <<EOH
AC3Db
MATERIAL "ac3dmat1" rgb 1 1 1  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
OBJECT world
kids 1
OBJECT poly
name "$name"
loc 0 0 0
numvert $numvert
EOH
;

foreach (@ver) {
   print "@$_\n";
}

print <<EOS
numsurf 1
SURF 0x21
mat 0
refs $numvert
EOS
;

for (my $i = 0; $i < $numvert; $i++) {
   print "$i 0 0\n";
}

print "kids 0\n";

exit;
