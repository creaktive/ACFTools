#!/usr/bin/perl -w
package Wing;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use Math::Trig;

use Airfoil;
use Surface;

@ISA		= qw(Exporter);
@EXPORT		= qw(wing);


sub wing {
   my %data = @_;

   $data{is_right} = 0 unless defined $data{is_right};

   my $file = $data{filehandle};
   my @incidence = @{$data{incidence}};
   my $elem = scalar @incidence;
   push @incidence, $incidence[-1];
   my ($fname, @foil) = airfoil ($data{foil});

   my @sec = ();
   my $elemx = ($data{root} - $data{tip}) / $elem;
   my $elemz = $data{semilen} / $elem;
   my $x = $data{root};
   my $z = 0;

   my $ns = 0;

   for (my $i = 0; $i <= $elem; $i++) {
      my $a = 0;
      my $b = $z;
      rotate (\$a, \$b, $data{sweep}) if $b;
      push @sec, wsec (
         $data{arm}, $data{is_right},
         $x, $a, $b,
         $incidence[$i],
         $data{dihed},
         @foil
      );
      $x -= $elemx;
      $z += $elemz;
   }

   my $nv = scalar @sec;
   print $file <<EOH
OBJECT poly
name "wing[$data{index}] // $fname"
loc 0 0 0
numvert $nv
EOH
   ;

   foreach my $ver (@sec) {
      print $file "@$ver\n";
   }

   my $nfv = scalar @foil;
   $ns += surface ($file, $elem + 1, $nfv, $data{is_right}, $data{material}, 2);
   closer ($file, $data{material}, $nv-$nfv..$nv-1);
   closer ($file, $data{material}, 0..$nfv-1);
   $ns += 2;

   print $file "kids 0\n";

   return ($nv, $ns);
}

sub wsec {
   my ($arm, $mirror, $size, $a, $b, $inc, $dih, @foil) = @_;
   local $_;
   my @wsec = ();
   for (my $i = 0; $i < @foil; $i++) {
      # define section
      my $x = ${$foil[$i]}[0];
      my $y = ${$foil[$i]}[1];
      my $z = $b;

      # rotate
      rotate (\$x, \$y, -$inc);

      # scale
      $x *= $size;
      $y *= $size;

      # sweep
      $x -= $a;

      # dihedral
      rotate (\$z, \$y, $dih);

      # axis
      my @ver = ();
      if ($mirror) {
         @ver = ($z, $y, $x);
      } else {
         @ver = (-$z, $y, $x);
      }

      # arm
      for (0..2) {
         $ver[$_] += $$arm[$_];
      }

      # save
      push @wsec, [@ver];
   }
   return @wsec;
}

sub rotate {
   my ($x, $y, $r) = @_;
   return if !$r || (!$$x && !$$y);
   my $d = sqrt ($$x**2 + $$y**2);
   my $a = acos ($$x / $d);
   $a *= -1 if $$y < 0;
   $a += deg2rad ($r);
   $$x = $d * cos ($a);
   $$y = $d * sin ($a);
   return;
}

sub closer {
   my ($file, $mat, @ver) = @_;
   print $file "SURF 0x30\n",
         "mat ", $mat, "\n",
         "refs ", scalar @ver, "\n";
   foreach my $ver (@ver) {
      print $file "$ver 0 0\n";
   }
   return;
}

1;
