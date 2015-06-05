#!/usr/bin/env perl
use strict;
use v5.10;
use Data::Dumper;

package Evo;

#used to pick random chars
our @CHARS = ('A' .. 'Z', 'a' .. 'z', ' ');

sub new {
	my $class = shift;
	my $self = { };
	bless $self, $class;
	$self->init(@_);
	return $self;
}

sub init {
	my ($self, %a) = @_;
	$$self{target} = $a{target};
	$$self{pool} = $a{pool} || [];
	$$self{display_every} = $a{display_every} || 10;
	$$self{steps} = $a{steps} || 1500;
}

sub random_char { $CHARS[rand $#CHARS] }

sub mutate {
	my ($str,$range) = @_;
	$range ||= 1;
	my $len = length $str;
	my $pos = int(rand $len);#pick random pos
	my @range = -$range .. $range;
	my $direction = $range[ rand( (2 * $range) + 1) ];
	my $char = substr($str, $pos, 1);
	my $ord = ord($char) + $direction;
	my $new_char = chr($ord);
	#replace a character
	substr($str, $pos, 1) = $new_char;
	return $str #mutated string
}

sub fitness {
	my ($str1,$str2) = @_;
	my $len = length $str1;
	my $val = 0;
	for my $i (0 .. $len-1) {
		#calculate eucledian distance
		$val += ( ord(substr $str1, $i, 1) - ord(substr $str2, $i, 1) ) ** 2;
	}
	return $val;
}

sub mate {
	my ($str1,$str2) = @_;
	my $new_str = $str1;
	my $len = length $str1;
	my $start = int(rand($len));
	my $stop  = int(rand($len));
	($start,$stop) = ($stop,$start) if $start > $stop;
	my $width = $stop - $start;
	substr $new_str, $start, $width, ( substr $str2,$start,$width );
	return $new_str
}

#============ Class methods ===========================================


sub display_pool {
	my $self = shift;
	say "pool>", join ', ', map { $$_{data} } @{$$self{pool}};
}

sub add2pool {
	my ($self, $str) = @_;
	my $fitness = 999_999_999;
	if ($$self{target}) {
		$fitness = fitness $str, $$self{target}
	}
	push @{$$self{pool}}, { data => $str, fitness => $fitness }
}


#generate random pool
sub gen_pool {
	my ($self,$size,$len) = @_;
	$len ||= length $$self{target};
	for my $el ( 1 .. $size ) {
		my $str = '';
		$str .= random_char for 1 .. $len;
		$self->add2pool($str);
	}
}

sub rand_pick { int( (rand * rand) * $_[0]) }
#select two parents for mixing, the lower the score better fitted for selection
sub pick_parents {
	my $self = shift;
	#two random nums with tendence to get higher numbers (!fixme make the random values unique, non-repeating)
	my $size = scalar @{$$self{pool}};
	my $rand1 = rand_pick($size);
	my $rand2 = rand_pick($size);
	$rand2 =  $rand1 == $rand2 ? rand_pick($size) : $rand2;

	#pick two with preference for lower dist (keys are dist, values are pool idx)
	@{$$self{sorted_idxs}} = sort { $$self{pool}[$b]{fitness} <=> $$self{pool}[$a]{fitness} } 0 .. $#{$$self{pool}};#reverse order
	my ($pidx1,$pidx2) = @{$$self{sorted_idxs}}[ $rand1, $rand2 ];
	#say "parents> $pidx1:$f1, $pidx2:$f2";
	return $pidx1, $pidx2
}


sub selection {
	my ($self,$mutated) = @_;
	#pick who will die, prefably the one furthest away
	my $die_idx = $$self{sorted_idxs}[0]; #max distance idx
	my $fit_score = fitness $$self{target}, $mutated;
	#replace parent with child in the population, but only if better genes
	if ($$self{pool}[$die_idx]{fitness} > $fit_score ) {
		$$self{pool}[$die_idx] = {data => $mutated, fitness => $fit_score }
	}
}

sub evolve {
	my ($self, $idx) = @_;

	#found it
	return 1 if $$self{pool}[ $$self{sorted_idx}[-1] ]{fitness} == 0;

	### CROSSOVER ###
	my ($pidx1,$pidx2) = $self->pick_parents();#find candidates for sex
	my $child = mate $$self{pool}[$pidx1]{data}, $$self{pool}[$pidx2]{data};

	### MUTATION ###
	my $mutated = mutate $child; #now introduce a mutation
	#say "ev> " . $$self{pool}[$pidx1]{data} . ' : ' . $$self{pool}[$pidx2]{data} . ' = ' . $mutated;

	### SELECTION ###
	$self->selection($mutated);

	return 0 #have not reached the target
}

sub iterate {
	my $self = shift;
	for my $iter (0 .. $$self{steps}) {
		#say "--> $iter";
		if ( $self->evolve ) {
			$$self{iterations} = $iter;
			return 1;
		}
		$self->display_pool if $iter % $$self{display_every} == 0;
	}
	$$self{iterations} = $$self{steps};
	return 0
}



package main;

my $e = new Evo(target => 'hello world', display_every => 100, steps => 5000);
say;
$e->gen_pool(10);
$e->display_pool;

say ">>>>>>>>>>>>>>>>>>>>>>";

if ( $e->iterate ) {
	$e->display_pool;
	say "evolved idx> " . Dumper( $$e{pool}[0] );
	say "iterations : ", $$e{iterations};
} else {
	say "could not evolve in that many iterations : ", $$e{iterations}
}
