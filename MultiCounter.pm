#!/usr/bin/perl -w
package MultiCounter;
require 5.008;

use strict;


sub init {
   my ($class, @counters) = @_;
   return '' unless scalar @counters;
   return '' if (scalar @counters) % 2;

   my %data;
   my $self = bless { %data }, $class;

   $self->{counters} = (scalar @counters) / 2 - 1;

   my (@from, @to, @inc, @now);
   my $total = 1;
   do {
      my $from = shift @counters;
      my $to = shift @counters;
      push @from, $from;
      push @to, $to;
      if ($from <= $to) {
         push @inc, 1;
         $total *= ($to - $from) + 1;
      } else {
         push @inc, -1;
         $total *= ($from - $to) + 1;
      }
   } while (@counters);

   @now = @from;

   $self->{from}	= [@from];
   $self->{to}		= [@to];
   $self->{inc}		= [@inc];
   $self->{now}		= [@now];

   $self->{total}	= $total;
   $self->{current}	= 0;
   $self->{remain}	= $total;

   return $self;
}

sub now {
   return @{$_[0]->{now}};
}
sub remain {
   return $_[0]->{remain};
}
sub current {
   return $_[0]->{current};
}
sub total {
   return $_[0]->{total};
}

sub next {
   my $self = shift;
   return '' unless $self->{remain};
   if ($self->{remain} > 1) {
      for (my $i = $self->{counters}; $i >= 0; $i--) {
         next if ${$self->{from}}[$i] == ${$self->{to}}[$i];
         if (${$self->{now}}[$i] == ${$self->{to}}[$i]) {
            ${$self->{now}}[$i] = ${$self->{from}}[$i];
            next;
         } else {
            ${$self->{now}}[$i] += ${$self->{inc}}[$i];
            last;
         }
      }
   }
   $self->{remain}--;
   $self->{current}++;
   return $self->now;
}

1;
