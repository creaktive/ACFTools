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

package Text::Quoter;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA		= qw(Exporter);
@EXPORT		= qw(quotescape quotunescape);


sub quotescape {
   local $_ = shift;
   s#\\#\\\\#g;
   s#"#\\"#g;
   s#([^\x20-\xfe]|\x7f)#sprintf '\x%x', ord $1#eg;
   return $_;
}

sub quotunescape {
   local $_ = shift;
   s#\\([\\"]|[x]?[\da-f]+)#local $_ = $1; /[\\"]/ ? $_ : chr (/^x(.+)/ ? hex : oct)#egi;
   return $_;
}

1;
