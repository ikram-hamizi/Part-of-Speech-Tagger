# !/usr/bin/perl
#********************************************************************************************************************************************************
#	
#								***************** Programming Assignment 3 (POS Tagger - SCORER) - VCU [14/03/2018] *****************
# Author    : Ikram Hamizi
# Class     : Intro. to NLP
# Professor : Bridget McInnes
# 
#********************************************************************************************************************************************************
# Description: Compare the New POS-Tagged file with the Gold Standard "pos-test-key.txt"
#
#********************************************************************************************************************************************************
#
# Input:  < NEW POS TAGGED FILE (scorer.pl pos-test-with-tags.txt pos-test-key.txt)
# Output: > Accuracy + Confusion Matrix (> pos-tagging-report.txt)
#
#********************************************************************************************************************************************************

use strict;
use Data::Dumper qw(Dumper);
use List::Util qw(max); #Module that has the "max" function
use List::MoreUtils qw(first_index);

my %HashNEW; #Hash of word-tag = count (one tag per-word).
my %HashGOLD;

my @word_tag = ();

my $token;

#1- Read and tokenize the new POS-Tagged file and store in hash table [word[tag]=count].
my @arraymynew;

open(HANDLERmynew, "<", "pos-test_wtih_tags.txt") or die "Could Not Open file: pos-test_wtih_tags.txt\n";
while(<HANDLERmynew>)
{
	chomp;
	@arraymynew = split (" ");
	for (my $i=0; $i<scalar @arraymynew; $i++)
	{
		$token = $arraymynew[$i];
		#2- Ensure no '[' or ']' are present
 		if($token =~m /^[\[\]]$/) 
		{
			#Remove from @array
			my $index_bracket = first_index { $_ eq $token } @arraymynew;
			splice @arraymynew, $index_bracket, 1; #offset:1 = delete:1
			$token = $arraymynew[$i]; #Update value of $token
		}

		#3- Ensure all $tokens in @array follow the patterns: (word/tag) - Remove ']'
		if ($arraymynew[$i] =~ m/\](w+)/)
		{
			$arraymynew[$i]=~s/\](w+)/$1/;
			$token = $arraymynew[$i];
		}

		#4- Record occurances of (word/tag) in a hash{word}{tag} : #E.g. Love/VB = 2 and Love/NN = 3.
		@word_tag = split('/', $token);
		# print @word_tag; #>>DEBUG
		# print "\n";
		$HashNEW{$word_tag[0]}{$word_tag[1]}++; #HashNEW has only one tag per word
	}
}
close(HANDLERmynew);


#2- Compare with GOLD
my @arrayGOLD;
@word_tag = (); #reset + reuse

open(HANDLERGOLD, "<", "pos-test-key.txt") or die "Could Not Open file: pos-test-key.txt\n";
while(<HANDLERGOLD>)
{
	chomp;
	@arrayGOLD = split (" ");
	for (my $i=0; $i<scalar @arrayGOLD; $i++)
	{
		$token = $arrayGOLD[$i];

		#1- Ensure all $tokens in @array follow the patterns: 'word/tag'
		if($token =~ m/\](w+)/)
		{
			$arrayGOLD[$i]=~s/\](w+)/$1/;
			$token = $arrayGOLD[$i];
		}

		#2- Ensure no '[' or ']' are present
	 	if($token =~m /^[\[\]]$/) 
		{
			#Remove from @array
			my $index_bracket = first_index { $_ eq $token } @arrayGOLD;
			splice @arrayGOLD, $index_bracket, 1; #offset:1 = delete:1
			$token = $arrayGOLD[$i]; #Update value of $token
		}

		#3- Record occurances of (word/tag) in a hash{word}{tag} : #E.g. Love/VB = 2 and Love/NN = 3.
		@word_tag = split('/', $token);
		$HashGOLD{$word_tag[0]}{$word_tag[1]}++; #HashNEW has only one tag per word
	}
}
close(HANDLERGOLD);

#3- Compare and fill the confusion matrix
my $incorrect_tags = 0;
my $total_tokens = 0;

my $predictedTagCOUNT = 0; #COUNT: from "New" POS-Tagged file
my $goldTagCOUNT = 0; 	   #COUNT: from "Key" GOLD-TAGGED TEST file

my $predictedTag;
my $realTag;

my %CONFUSION2D; #[Fake][Real] = count 

for my $word (keys %HashNEW)
{
	for my $tag (keys %{$HashNEW{$word}}) #1 Loop - (one tag per-word)
	{
		print "Tag: $tag\n";
		#1- Get the tags from $tag and %HashGOLD
		$predictedTagCOUNT = max values %{$HashNEW{$word}}; #int
		my @winners = grep { ${HashNEW{$word}}{$_} eq $predictedTagCOUNT } keys %{$HashNEW{$word}};
		$predictedTag = $winners[0]; #Catching the only tag (1 per word)

		#2- TOTAL UPDATE: predictedTagCOUNT = occurance of $word
		$total_tokens += $predictedTagCOUNT;

		$goldTagCOUNT = max values %{$HashGOLD{$word}}; #int
		my @winners = grep { ${HashGOLD{$word}}{$_} eq $goldTagCOUNT } keys %{$HashGOLD{$word}};
		$realTag = $winners[0]; #Catch the only tag (1 per word)

		#3- Compare the two tags
		if ($predictedTag ne $realTag) 
		{
			$incorrect_tags++;
			print "INCORRECT: fake($predictedTag) vs real($realTag)\n";
			print "- Token: ($word)\n\n";
		}
		#4-Add tags to confusion matrix or increment if existing
		$CONFUSION2D{$predictedTag}{$realTag} += $predictedTagCOUNT;
	}
}

#4- Confusion Matrix
print "------------------------\n";
print Dumper \%CONFUSION2D;
print "------------------------\n";

print "TOTAL = $total_tokens | Incorrect = $incorrect_tags\n";
#5- CALCULATE ACCURACY

if($total_tokens ne 0)
{
	my $ACCURACY = ($total_tokens-$incorrect_tags)/$total_tokens * 100;
	print "Accuracy of tagger.pl = $ACCURACY %\n";
}
else
{
	print "Error: No test or training text was used\n";
}
