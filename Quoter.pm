#!/usr/bin/perl -w
package Quoter;

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
