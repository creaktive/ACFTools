#!/usr/bin/perl -w
package AC3Dgen;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use GetFoil;
use Surface;
use Wing;

@ISA		= qw(Exporter);
@EXPORT		= qw(AC3Dgen);


sub AC3Dgen {
   my ($plain, $ac3d, $nowings, $min, $max, @force) = @_;
   local $_;
   $min = 44 unless defined $min;
   $max = 66 unless defined $max;

   # X-Plane constants
   my $secnum = 12;
   my $versec = 18;
   my $vernum = $secnum * $versec;

   my @par = @force;
   my @arm = ();
   my @ver = ();
   my @wng = ();
   my @bcw = ();
   my @nbl = ();

   open (TXT, $plain) || die "Can't open $plain: $!\n";
   while (<TXT>) {
      chomp;
      s%\s+$%%;
      s%//.*$%%;
      next unless $_;

      my ($type, $lval, $rval) = split /\s+/, $_, 3;
      if ($lval =~ /_prop_dir\[(\d+)\]/) {
         $bcw[$1] = &clean ($rval);
      } elsif ($lval =~ /_num_blades\[(\d+)\]/) {
         $nbl[$1] = &clean ($rval);
      } elsif ($lval =~ /_part_eq\[(\d+)\]/) {
         my $part = $1;
         $rval =~ s/^.*\s//;
         push @par, $part if $rval && not grep $_ == $part, @par;
      } elsif ($lval =~ /_els\[(\d+)\]/) {
         wparm (\@wng, $1, '_elements', $rval);
      } elsif ($lval =~ /_Rafl0\[(\d+)\]/) {
         wparm (\@wng, $1, '_Rafl0', $rval);
      } elsif ($lval =~ /_arm\[(\d+)\]/) {
         my $part = $1;
         @{$arm[$part]} = &vert ($rval);
      } elsif ($lval =~ /_Croot\[(\d+)\]/) {
         wparm (\@wng, $1, 'root', $rval);
      } elsif ($lval =~ /_Ctip\[(\d+)\]/) {
         wparm (\@wng, $1, 'tip', $rval);
      } elsif ($lval =~ /_semilen_SEG\[(\d+)\]/) {
         wparm (\@wng, $1, 'semilen', $rval);
      } elsif ($lval =~ /_dihed1?\[(\d+)\]/) {
         wparm (\@wng, $1, 'dihed', $rval);
      } elsif ($lval =~ /_sweep1\[(\d+)\]/) {
         wparm (\@wng, $1, 'sweep', $rval);
      } elsif ($lval =~ /_(?:incidence|anginc)\[(\d+)\]\[(\d+)\]/) {
         my $ind = $1;
         my $inc = $2;
         ${${$wng[$ind]}{incidence}}[$inc] = &clean ($rval);
      } elsif ($lval =~ /_body\[(\d+)\]/) {
         my $part = $1;
         next unless grep $_ == $part, @par;
         my @v = &vert ($rval);

#         next if $v[0] == 0 && $v[1] == 0 && $v[2] == 0;

         if (defined $arm[$part]) {
            for (my $i = 0; $i < 3; $i++) {
               $v[$i] += ${$arm[$part]}[$i];
            }
         }

         push @{$ver[$part]}, [@v];
      }
   }
   close TXT;


   open (AC3D, ">$ac3d") || die "Can't write to $ac3d: $!\n";
   print AC3D <<EOH
AC3Db
MATERIAL "ac3dmat1" rgb 1 1 1  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
MATERIAL "ac3dmat13" rgb 0.533333 0.533333 0.533333  amb 0.2 0.2 0.2  emis 0 0 0  spec 0.5 0.5 0.5  shi 10  trans 0
OBJECT world
kids _DUNNO_
EOH
   ;


   my $nv = 0;
   my $ns = 0;
   my $np = 0;


   my $wingn = $nowings ? 0 : @wng;
   for (my $ind = 0; $ind < $wingn; $ind++) {
      my %wing = %{$wng[$ind]};
      next if not defined $wing{semilen} or not $wing{semilen};
      next unless grep $_ == $ind, @par;

      $wing{arm}	= $arm[$ind];
      $wing{filehandle}	= \*AC3D;
      $wing{index}	= $ind;
      $wing{is_right}	= $ind % 2;
      $wing{material}	= 0;

      die "Parser: incomplete incidence table\n" if @{$wing{incidence}} < $wing{_elements};
      splice @{$wing{incidence}}, $wing{_elements};
      delete $wing{_elements};

      # left vstab
      $wing{dihed} = 180 - $wing{dihed} if $ind == 18;

      my $foil = getfoil ($wing{_Rafl0});
      if ($foil) {
         print STDERR "generating wing[$ind] using airfoil $foil\n";
         $wing{foil} = $foil;
      } else {
         print STDERR "\n", '#'x78, "\n",
                      "No airfoil definition found for \"$wing{_Rafl0}\"!\n",
                      "Please describe it in 'airfoil.lst' file found in 'data' sub-directory.\n",
                      '#'x78, "\n";
         close AC3D;
         unlink $ac3d;
         return;
      }
      delete $wing{_Rafl0};

      my $gen = sub {
         my ($wnv, $wns) = wing (%wing);
         $nv += $wnv;
         $ns += $wns;
         $np ++;
      };

      # propellers
      if ($ind <= 7) {
         $wing{is_right} = $bcw[$ind] > 0 ? 1 : 0;
         for (my $i = 0; $i < @{$wing{incidence}}; $i++) {
            ${$wing{incidence}}[$i] -= 90;
         }
         for (my $i = 1, $wing{dihed} = 90; $wing{dihed} < 450; $i++, $wing{dihed} += 360 / $nbl[$ind]) {
            $wing{index} = "BLADE($ind,$i)";
            &$gen;
         }
      } else {
         &$gen;
      }

#      foreach my $key (sort keys %wing) {
#         my $val;
#         if (ref $wing{$key} eq 'ARRAY') {
#            $val = '[' . join (', ', @{$wing{$key}}) . ']';
#         } else {
#            $val = $wing{$key};
#         }
#         printf DBUG "%-16s=> %s,\n", $key, $val;
#      }
   }


   foreach my $part (@par) {
      unless (grep $_ == $part, @force) {
         next if ($part < $min or $part > $max);
      }

      my $nver = scalar @{$ver[$part]};
      $nv += $nver;
      $np++;

      print AC3D <<EOO
OBJECT poly
name "body[$part]"
numvert $nver
EOO
   ;

      foreach my $ver (@{$ver[$part]}) {
         print AC3D "@$ver\n";
      }

      $ns += surface (\*AC3D, $secnum, $versec, 1, 1);
      print AC3D "kids 0\n";
   }

   close AC3D;


   local @ARGV = ($ac3d);
   $^I = '~';
   while (<>) {
      s/_DUNNO_/$np/;
      print $_;
   }
   unlink "$ac3d~";


   return $nv, $ns, $np;
}

sub vert {
   local $_ = &clean (shift);
   s/.*{\s+//;
   s/\s+}.*//;
   my @v = split /\s*,\s*/, $_;
   die "Parser: broken vertex\n" unless @v == 3;
   return @v;
}

sub clean {
   local $_ = shift;
   s/^.*=\s*"?//;
   s/"?\s*$//;
   return $_;
}

sub wparm {
   my ($wng, $ind, $key, $val) = @_;
   ${${$wng}[$ind]}{$key} = &clean ($val);
   return;
}

1;
