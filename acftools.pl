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

require 5.008;

use strict;
use File::Basename;
use File::Copy;
use File::Spec::Functions;

use vars qw($VERSION);
$VERSION = '0.5';
use constant DEFS	=> 'defs';
use constant LIB	=> 'lib';

BEGIN { $0 = $^X unless $^X =~ m%(^|[/\\])(perl)|(perl.exe)$%i }
use FindBin;

use Getopt::Long;
use IO::Handle;
STDERR->autoflush (1);

use Time::HiRes qw(gettimeofday);
use vars qw($pbart);
$pbart = 0;

use lib catfile (dirname ($FindBin::RealScript), LIB);
use XPlane::Convert::ACFgen;
use XPlane::Convert::ACFparse;
use XPlane::Convert::AC3Dgen;
use XPlane::Convert::AC3Dmerge;


print STDERR '#'x78, "\n";
print STDERR <<HEADER
[ACFTools v$VERSION] Set of tools to play with ACF files outside of Plane-Maker
Perl script and modules coded by Stanislaw Pusep <stanis\@linuxmail.org>
Site of this and another X-Plane projects of mine:
<http://www.x-plane.org/users/stas/>

Allows you to:
 * export X-Plane (www.x-plane.com) aircraft data files to human-editable
   plaintext format and 3D mesh editable in AC3D modeler (www.ac3d.org).
 * import plaintext/3D mesh back to ACF file.
HEADER
;
print STDERR '#'x78, "\n"x2;


my $def		= 'ACF700.def';
my $ext		= "\xa";
my $gen		= 0;
my $mer		= 0;
my $nac		= 0;
my $nor		= 0;
my $min		= 44;
my $max		= 66;
my @force	= ();
my $acf		= '';
my $txt		= '';
my $ac3		= '';
my $normalize	= 9;

GetOptions (
	'extract:s'	=> \$ext,
	generate	=> \$gen,
	merge		=> \$mer,
	noac3d		=> \$nac,
	noorder		=> \$nor,
	'minbody=i'	=> \$min,
	'maxbody=i'	=> \$max,
	'force=s'	=> \@force,
	'acffile=s'	=> \$acf,
	'txtfile=s'	=> \$txt,
	'ac3dfile=s'	=> \$ac3,
	'normalize=i'	=> \$normalize,
);

@force = split /\s*,\s*/, join (',', @force);
if ($ext eq "\xa") {
   $ext = 0;
} elsif ($ext) {
   $def = $ext;
   $ext = 1;
} else {
   $ext = 1;
}
$def = catfile ($FindBin::RealBin, DEFS, $def) unless -f $def;


if ($ext && $acf) {
   die "Supported file extensions: .ACF & .WPN\n" unless $acf =~ /\.(acf|wpn)$/i;

   $txt = &chtype ($acf, 'txt')		unless $txt;
   $ac3 = &chtype ($txt, 'ac')		if not $ac3 and not $nac;

   print STDERR " * '$acf' => '$txt'\n";
   &doesexists ($txt);
   &acf2plain ($def, $acf, $txt);
   unless ($nac) {
      print STDERR "\n\n * '$txt' => '$ac3'\n";
      &doesexists ($ac3);
      &plain2ac3d ($txt, $ac3, $normalize, $min, $max, @force);
   }
} elsif ($ext && $txt) {
   die "Supported file extension: .TXT\n" unless $txt =~ /\.txt$/i;

   $ac3 = &chtype ($txt, 'ac')		unless $ac3;

   print STDERR " * '$txt' => '$ac3'\n";
   &doesexists ($ac3);
   &plain2ac3d ($txt, $ac3, $normalize, $min, $max, @force);
} elsif ($gen && $txt) {
   die "Supported file extension: .TXT\n" unless $txt =~ /\.txt$/i;

   $acf = &chtype ($txt, 'acf')		unless $acf;

   print STDERR " * '$txt' => '$acf'\n";
   &doesexists ($acf);
   &plain2acf ($txt, $acf);
} elsif ($mer && $ac3) {
   die "Supported file extension: .AC\n" unless $ac3 =~ /\.ac$/i;

   $txt = &chtype ($ac3, 'txt')		unless $txt;
   die "Supported file extension: .TXT\n" unless $txt =~ /\.txt$/i;

   print STDERR " * '$ac3' => '$txt'\n\n";
   unless (-e $txt) {
      print STDERR "File to be patched does not exists!\n";
   } else {
      my ($nv, $nl) = AC3Dmerge ($ac3, $txt, $nor);
      print STDERR "Merged $nv vertices in $nl lines file\n";
   }
} else {
   print STDERR <<USAGE
Usage: $FindBin::RealScript <commands> [parameters]
 o Commands:
	-extract DEF	: extract TXT from ACF
	-generate	: generate ACF from TXT
	-merge		: merge body from AC3D file to TXT
 o Parameters:
	-acffile FILE	: name of ACF file to process
	-txtfile FILE	: name of TXT file to process
	-ac3dfile FILE	: name of AC3D file to process
	-noorder	: DO NOT sort vertices while merging bodies
	-noac3d		: DO NOT generate AC3D
	-(min|max)body N: write all bodies in specified range to AC3D
	-force LIST	: force extraction of bodies LIST (comma-separated N)
	-normalize N	: normalize wings to N vert/surface (N>=2 or no wings!)
 o Notes:
	* You can use abbreviations of commands/parameters (-gen or even -g
	  instead of -generate).
	* The only required parameter for "extract" command is -acffile.
	  Both -txtfile and -ac3dfile are derivated from it.
	* "generate" command and -txtfile has the same relation.
	* By default "extract" uses the latest DEF file.
	* "generate" doesn't need DEF at all (it is implicit in TXT)
	* If file to be created already exists backup is made automatically.
 o Examples:
	$FindBin::RealScript --extract=ACF700.def --acffile="F-22 Raptor.acf"
	(extract 'F-22 Raptor.txt' from 'F-22 Raptor.acf')

	$FindBin::RealScript -e -acf "F-22 Raptor.acf"
	(same as above)

	$FindBin::RealScript -me -ac3d ladar.ac -txt "F-22 Raptor.txt"
	(merge *single* 3D body from 'ladar.ac' to 'F-22 Raptor.txt')

	$FindBin::RealScript -g -txt "F-22 Raptor.txt"
	(reverse operation; generate 'F-22 Raptor.acf' from 'F-22 Raptor.txt')
USAGE
;
}


&leave;


sub acf2plain {
   my ($def, $acf, $plain) = @_;

   my @xyz = ();
   my @anm = ();
   my $dim = 1;
   my $count = 0;
   my $out = sub {
      my ($type, $name, $array, $value, $lines, $comment) = @_;

      my $macro = '';
      if ($name =~ /^(\w+ins)_[xy]$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1;
         $dim = 2;
      } elsif ($name =~ /^(\w+ins_del)[xy]$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1;
         $dim = 2;
      } elsif ($name =~ /^(\w+)[XYZ](arm)$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1.$2;
         $dim = 3;
      } elsif ($name =~ /^(\w+)[XYZ]_(body_aero)$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1.$2;
         $dim = 3;
      } elsif ($name =~ /^(\w+body)_[XYZ]$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1;
         $dim = 3;
      } elsif ($name =~ /^(\w+)[xyz](nodef)$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1.$2;
         $dim = 3;
      } elsif ($name =~ /^(\w+tank)_[XYZ]$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1;
         $dim = 3;
      } elsif ($name =~ /^(\w+)[XYZ](wpn_att)$/) {
         push @xyz, $value;
         push @anm, $array;
         $macro = $1.$2;
         $dim = 3;
      }

      if ($macro) {
         $count++;
      } else {
         &fixtabs (sprintf ("%4s\t%s%s", $type, $name, $array), $value, $comment);
      }

      if ($count && $lines * $dim == $count) {
         my $xyz = scalar @xyz;
         die "Postparser: XYZ macro broken!\n" if $xyz % $dim;
         for (my $i = 0; $i < $lines; $i++) {
            my @ver = ();
            push @ver, $xyz[$i];
            push @ver, $xyz[$i + $lines];
            push @ver, $xyz[$i + $lines * 2] if $dim == 3;
            &fixtabs (
               sprintf ("xv%dd\t%s%s", $dim, $macro, $anm[$i]),
               '{ '.join (', ', @ver).' }',
               $comment,
            );
         }
         $macro = '';
         @xyz = @anm = ();
         $count = 0;
         $dim = 1;
      }
   };

   my @stat = stat $acf;
   die "Can't access $acf: $!\n" unless @stat;
   print STDERR "\nparsing...\n\n";

   open (OUT, ">$plain") || die "Can't write to $plain: $!\n";
   printf OUT "// X-Plane aircraft '%s' has last modified time [%s]\n", $acf, scalar localtime $stat[9];

   my $old = select OUT;
   my $time = time;
   my $total = ACFparse ($def, $acf, $out, \&progress);
   $time = time - $time;
   select $old;

   printf OUT "// Successfully parsed using '%s'\n", basename ($def);
   close OUT;

   print STDERR "\n\ndone!\n",
                "processed $total of $stat[7] bytes in $time seconds\n";

   return;
}

sub plain2ac3d {
   my ($plain, $ac3d, $normalize, $min, $max, @force) = @_;

   print STDERR "\nextracting bodies $min..$max & ", (($normalize < 2) ? 'NO' : 'all'), " wings\n";
   print STDERR "(also forcing bodies [", join (',', @force), "])\n" if @force;

   my ($nv, $ns, $no) = AC3Dgen ($plain, $ac3d, $normalize, $min, $max, @force);

   if (defined $nv) {
      print STDERR "dumped $nv vertices and $ns surfaces within $no objects\n";
   }
   return;
}

sub plain2acf {
   print STDERR "\n";
   my ($total, $lines) = ACFgen ($_[0], $_[1], \&progress);
   print STDERR "\n\nwrote $total bytes processing $lines lines\n";

   return;
}


sub leave {
   if ($^O =~ /^mswin/i) {
      print STDERR "\n\n * Press <RETURN> to exit...";
      <STDIN>;
   }
   exit;
}

sub progress {
   my ($total, $now) = @_;
   my $time = scalar gettimeofday;
   if ($time - $pbart >= 0.01) {
      my $prc = (100 * $now) / $total;
      my $bar = '=' x int ($prc / 2);
      printf STDERR "(%-50s) %6.2f%% complete\r", $bar, $prc;
   }
   $pbart = $time;
   return;
} 

sub fixtabs {
   my ($lval, $rval, $comment) = @_;
   return if not defined $rval or $rval eq '';
   my $pad = 53 - length $lval;
   my $tabs = int ($pad / 8);
   $tabs++ if $pad % 8;
   my $ccom = $comment ? "\t// $comment" : '';
   printf "%s%s= %s%s\n", $lval, "\t" x $tabs, $rval, $ccom;

   return;
}

sub chtype {
   my ($name, $path, $type) = fileparse shift, qr{\..*};
   return $path.$name.'.'.shift;
}

sub doesexists {
   my $file = shift;
   my $bak = "$file.bak";
   if (-e $file) {
      print STDERR "File already exists! Saving $bak\n";
      move ($file, $bak) || die "Can't backup $file: $!\n";
   }
   return;
}
