#!/usr/bin/perl -w
package AC3Dmerge;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use AC3Dparse;

@ISA		= qw(Exporter);
@EXPORT		= qw(AC3Dmerge);


sub AC3Dmerge {
   my ($ac3, $txt, $noorder) = @_;
   local $_;

   my ($name, @ver) = AC3Dparse ($ac3);
   my $numvert = scalar @ver;
   if ($numvert != 360) {
      print STDERR "Warning: I expect 360 vertices and $ac3 has $numvert\n";
   }
   $name = quotemeta $name;

   @ver = ACForder (18, @ver) unless $noorder;

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
         if (@ver) {
            $line = $start . '{ ' . join (', ', @{shift @ver}) . " }\n";
            $nv++;
         } else {
            $line = $start . '{ 0, 0, 0 }' . "\n";
            $dfct++;
         }
      }
   } continue {
      print $line;
      $nl++;
   }

   if ($dfct) {
      printf STDERR "Import warning: %d vertex deficit!\n", $dfct;
   } elsif (@ver) {
      printf STDERR "Import warning: %d vertex exceeded!\n", scalar @ver;
   }

   return ($nv, $nl);
}

1;
