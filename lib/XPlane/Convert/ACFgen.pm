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

package XPlane::Convert::ACFgen;

require 5.008;

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

use Config;
use Fcntl qw(O_CREAT O_WRONLY);
use Text::Quoter;

@ISA		= qw(Exporter);
@EXPORT		= qw(ACFgen);


sub ACFgen {
   my ($plain, $acf, $progress) = @_;
   local $_;

   my @ver = ();
   my $vty = '';
   my $oldname = '';

   open (TXT, $plain) || die "Can't open $plain: $!\n";
   my $size = (stat TXT) [7];

   sysopen (ACF, $acf, O_CREAT|O_WRONLY, 0644) || die "Can't write to $acf: $!\n";
   binmode ACF;

   my $total = 0;
   my $script = 0;
   my $lines = 0;

   my $dumpver = sub {
      my (@x, @y, @z);
      foreach my $ver (@ver) {
         push @x, $$ver[0];
         push @y, $$ver[1];
         push @z, $$ver[2] if @$ver == 3;
      }
      foreach my $ver (@x, @y, @z) {
          $total += &writepacked (\*ACF, 'xflt', $ver, undef);
      }
      @ver = ();
   };

   while (<TXT>) {
      $lines++;
      $script += length $_;
      &$progress ($size, $script) if defined $progress;

      chomp;
      s%//.*$%%;
      s/\s+$//;
      s/^\s+//;
      next unless $_;

      my @line = split (/\s+/, $_, 3);
      die "Parser: broken line (unable to split)\n" unless @line == 3;
      my ($type, $lval, $rval) = @line;

      my ($name, $array) = ($lval =~ /^(\w+)(?:\[(.*)\])?$/);
      die "Parser: broken line (regex doesn't matches)\n" unless defined $name;
      my @array = ();
      @array = split /\]\[/, $array if defined $array;

      if ($name =~ /PlatForm/i) {
         my $platform = $Config{archname} =~ /\bx86\b/i ? 'i' : 'a';
         $total += &writepacked (\*ACF, 'xchr', ord ($platform), undef);
         next;
      }

      if ($oldname && @ver && $oldname ne $name) {
#         printf "// %s %s[%d]\n", $vty, $oldname, scalar @ver;
         &$dumpver;
      }

      $rval =~ s/^\s*=\s*//;
      my $value = '';
      if ($rval =~ /^"(.*)"$/) {
         $value = quotunescape $1;
      } elsif ($rval =~ /^{\s*(.+?)\s*}$/) {
         $value = [split /\s*,\s*/, $1];
         push @ver, $value;
         $vty = $type;
      } else {
         $value = $rval;
      }

      unless (@ver) {
#         printf "[%s] <%s> '%s'\n",
#                $name,
#                join (',', @array),
#                (ref $value eq 'ARRAY') ? (join (',', @$value)) : $value;
          $total += &writepacked (\*ACF, $type, $value, pop @array);
      }

      $oldname = $name;
   }
   close TXT;

   &$dumpver if @ver;
   close ACF;

   return $total, $lines;
}

sub writepacked {
   my ($file, $type, $value, $sizeof) = @_;

   my %types = (
	xchr	=> 'Z',
	xflt	=> 'f',
	xint	=> 'i',
   );
   my $packer = $types{$type};

   if ($type eq 'xchr') {
      unless (defined $sizeof) {
         $sizeof = 1;
         $packer = 'c';
      } else {
         $packer .= $sizeof;
      }
   } else {
      $sizeof = 4;
   }

#   print "$type\t$value\t[$packer]\n";
   my $r = syswrite ($file, pack ($packer, $value), $sizeof);
   die "Can't write to $file: $!\n" unless defined $r;
   return $r;
}

1;
