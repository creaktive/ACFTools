#!/usr/bin/perl -w
package Surface;

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
