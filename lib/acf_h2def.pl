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


# Usage: take good old 'X-Plane ACF_format.html'; copy structure you like
# (DO NOT include leading & trailing brackets "{}"!) to ACFx.h. Then:
# perl acf_h2def.pl < ACFx.h > ACFx.def
# After that open ACFx.def in your favourite text editor & replace
# dumped constant names with respective values.


use strict;

my %const = ();
my $i = 0;
while (<>) {
   $i++;
   chomp;
   s/^\s+//;
   s%//.*$%%;
   s/\s+$//;
   next unless $_;

   foreach my $entry (split /\s*;\s*/, $_) {
      my (@parse) = ($entry =~ /^(\w+?)\s+(.+)$/);
      if (@parse != 2) {
         print "bad record at line $i\n";
      }

      my $type = shift @parse;
      foreach my $var (split /\s*,\s*/, shift @parse) {
         $var =~ s%\s*\[\s*%[%g;
         $var =~ s%\s*\]\s*%]%g;
         ++$const{$1} while $var =~ /\[([^\d].*?)\]/g;

         print "$type $var\n";
      }
   }
}

print STDERR "\n\nArray dimension constants:\n";
foreach my $const (sort keys %const) {
   print STDERR "$const\n";
}

exit;
