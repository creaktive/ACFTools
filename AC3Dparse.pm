#!/usr/bin/perl -w
package AC3Dparse;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA		= qw(Exporter);
@EXPORT		= qw(AC3Dparse ACForder);


sub AC3Dparse {
   my $ac3 = shift;
   local $_;

   open (AC3D, $ac3) || die "Can't open $ac3: $!\n";
   $_ = <AC3D>;
   die "Unknown AC3D file format!\n" unless /^AC3Db/i;

   my $kids = &seek_key (\*AC3D, 'kids');
   die "Unable to work with multiple objects!\n" if $kids != 1;
   my $name = &seek_key (\*AC3D, 'name');
   $name =~ s/^"//;
   $name =~ s/"$//;
   my $numvert = &seek_key (\*AC3D, 'numvert');

   my @ver = ();
   my @max = qw(0 0 0);
   my @min = qw(0 0 0);
   for (my $i = 0; $i < $numvert; $i++) {
      $_ = <AC3D>;
      chomp;
      s/\s+$//;
      my @v = split /\s+/, $_;
      die "Vertex #$i doesn't looks good!\n" unless @v == 3;
      push @ver, [@v];

      &centre (\@v, \@min, \@max);
   }
   die "$ac3 seems to be broken!\n" if scalar @ver != $numvert;
   close AC3D;

   my @arm = ();
   for (0..2) {
      $arm[$_] = $min[$_] + (($max[$_] - $min[$_]) / 2);
   }

   for (my $i = 0; $i < $numvert; $i++) {
      for (0..2) {
         ${$ver[$i]}[$_] -= $arm[$_];
      }
   }

   return ($name, @ver);
}

sub ACForder {
   my ($verps, @ver) = @_;
   my $numvert = scalar @ver;
   die "AC3D file can't be ordered in $verps-vertex sections!\n" if $numvert % $verps;

   my @sort = ();
   my (@max, @min);
   for (my $i = 0; $i < $numvert / $verps; $i++) {
      my %sort = ();
      my @sect = splice @ver, 0, $verps;

      @max = qw(0 0 0);
      @min = qw(0 0 0);
      my ($xs, $ys) = qw(0 0);
      foreach my $v (@sect) {
         $xs += $$v[0];
         $ys += $$v[1];
         &centre ($v, \@min, \@max);
      }
      my $xo = $min[0] + (($max[0] - $min[0]) / 2);
      my $yo = $min[1] + (($max[1] - $min[1]) / 2);

      if ($xs == 0) {
         foreach my $v (sort { $$a[0] <=> $$b[0] } @sect) {
            push @sort, $v;
         }
      } elsif ($ys == 0) {
         foreach my $v (sort { $$a[1] <=> $$b[1] } @sect) {
            push @sort, $v;
         }
      } else {
         foreach my $v (@sect) {
            my ($x, $y) = @$v;
            $x -= $xo;
            $y -= $yo;
            my $d = sqrt ($x**2 + $y**2);
            my $a = $d ? $y / $d : 0;
            $a = -$a - 2 if $x > 0;
            $a /= 10;

            while (defined $sort{$a}) {
               $a .= '0';
            }
            $sort{$a} = $v;
         }
         my @order = sort { $a <=> $b } keys %sort;
         if ($order[0] == $order[1]) {
            push @order, shift @order;
         } elsif ($order[-1] == $order[-2]) {
            unshift @order, pop @order;
         }

         foreach my $a (@order) {
#            printf STDERR "%.5f\t{ %.5f, %.5f, %.5f }\n", $a, @{$sort{$a}};
            push @sort, $sort{$a};
         }
#         print STDERR "\n";
      }
   }

   return @sort;
}

sub seek_key {
   my ($file, $key) = @_;
   local $_;
   my $val = '';
   while (<$file>) {
      chomp;
      s/\s+$//;
      if (/^$key\s+(.+)$/i) {
         $val = $1;
         last;
      }
   }
   return $val;
}

sub centre {
   my ($ver, $min, $max) = @_;
   for (my $i = 0; $i < @$ver; $i++) {
      if (!$$max[$i] || $$ver[$i] > $$max[$i]) {
         $$max[$i] = $$ver[$i];
      } elsif (!$$min[$i] || $$ver[$i] < $$min[$i]) {
         $$min[$i] = $$ver[$i];
      }
   }
   return;
}

1;
