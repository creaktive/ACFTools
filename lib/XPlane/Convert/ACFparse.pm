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

package XPlane::Convert::ACFparse;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);
use vars qw($endian_swap);

use Config;
use Fcntl qw(O_RDONLY SEEK_SET SEEK_CUR SEEK_END);
use MultiCounter;
use Text::Quoter;

@ISA		= qw(Exporter);
@EXPORT		= qw(ACFparse);


sub ACFparse {
   my ($def, $acf, $out, $progress) = @_;
   local $_;

   sysopen (ACF, $acf, O_RDONLY) || die "Can't open $acf: $!\n";
   binmode ACF;

   sysread (ACF, $_, 1) || die "Can't read signature from $acf: $!\n";
   my ($arch) = unpack 'a', $_;
   my $file_is_x86 = $arch =~ /i/i ? 1 : 0;
   my $arch_is_x86 = $Config{archname} =~ /\bx86\b/i ? 1 : 0;
   if (($file_is_x86 and not $arch_is_x86) or (not $file_is_x86 and $arch_is_x86)) {
      print STDERR '#'x78, "\n",
                   "WARNING: file wasn't created on same architecture as yours!\n",
                   "If you experience errors, load '$acf' in Plane-Maker\n",
                   "and simply do 'File->Save'. This will fix ACF to native format.\n",
                   '#'x78, "\n"x2;
      $endian_swap = 1;
   } else {
      $endian_swap = 0;
   }
   my $magic = sprintf "%s-oriented file parsed on %s platform", $file_is_x86 ? 'Intel' : 'Apple', $Config{archname};

   sysread (ACF, $_, 4) || die "Can't read signature from $acf: $!\n";
   $_ = reverse $_ if $endian_swap;
   my $version = unpack 'i', $_;
   print STDERR "ACF appears to come from X-Plane version [$version]\n\n";

   sysseek (ACF, 0, SEEK_SET);

   open (DEF, $def) || die "Can't open $def: $!\n";
   my @def = <DEF>;
   close DEF;

   my %types = (
	xchr	=> 'Z',
	xflt	=> 'f',
	xint	=> 'i',
   );
   my $types = join '|', sort keys %types;
   my $total = 0;

   for (my $i = 0; $i < scalar @def; $i++) {
      $_ = $def[$i];
      chomp;
      s/\s+$//;

      my $comment = '';

      my ($type, $varname, $array) = /^($types)\s+([\s\w]+)(?:\[(.*)\])?/i;
      my $name = $varname;
      $name =~ s/\s.*\s//g;
      my @array = ();
      @array = split /\]\[/, $array if defined $array;

      my $unpacker = $types{$type};
      $array = '';
      if ($type eq 'xchr') {
         if (@array >= 1) {
            my $n = pop @array;
            $unpacker .= $n;
            $array = "[$n]";
         } else {
            $unpacker = 'c';
         }
      }

      my $lines = 1;
      foreach my $line (@array) {
         $lines *= $line;
      }

      &$progress (scalar @def, $i + 1) if defined $progress;

      unless (@array) {
         my ($value, $r) = &ACFread (\*ACF, $unpacker);
         $total += $r;
         if ($magic) {
            $comment = $magic;
            $magic = '';
         }
         &$out ($type, $name, $array, $value, $lines, $comment);
      } else {
         for (my $c = init MultiCounter (map { (0, --$_) } @array); $c->remain; $c->next) {
            my $carray = '['.join ('][', $c->now).']';
            my ($value, $r) = &ACFread (\*ACF, $unpacker);
            $total += $r;
            &$out ($type, $name, $carray.$array, $value, $lines, $comment);
         }
      }
   }

   close ACF;

   return $total;
}

sub ACFread {
   my ($file, $unpacker) = @_;
   my $buf = '';

   my $sizeof = 4;
   my $string = '%d';
   if ($unpacker =~ /^Z(\d+)/) {
      $sizeof = $1;
      $string = '"%s"';
   } elsif ($unpacker =~ /^c/) {
      $sizeof = 1;
   } elsif ($unpacker =~ /^f/) {
      $string = '%g';
   }

   my $r = sysread ($file, $buf, $sizeof);
   not defined $r and die "Can't read from ACF: $!\n";
   return ('', 0) unless $r;

   my $is_num = $unpacker =~ /^[fi]/ ? 1 : 0;
   $buf = reverse $buf if $endian_swap && $is_num;

   # Mac Fuk
   $buf = "\0"x4 if $buf eq "\1\0\0\0" && $unpacker =~ /^f/;

   my $unpacked = unpack $unpacker, $buf;
   $unpacked = quotescape $unpacked if $string =~ /^"/;
   $unpacked = -1 if $unpacked =~ /#/;
   return sprintf ($string, $unpacked), $r;
}
 
1;
