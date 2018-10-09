# !/usr/bin/perl

#********************************************************************************************************************************************************
#	
#								***************** Programming Assignment 3 (POS TAGGER) - VCU [14/03/2018] *****************
# Author    : Ikram Hamizi
# Class     : Intro. to NLP
# Professor : Bridget McInnes
# 
#********************************************************************************************************************************************************
#   DESCRIPTION: 

#	A program that implements the "most likely tag" baseline. 
#	-Each word in the Training Data is assigned to the POS tag that maximizes p(tag|word).
#	-Assumption: Any word found in Test Data but not in Training Data (i.e an unknown word) is an NN 
#   (+finding the accuracy of most likely Tagger on a given Test file).
#   ------------
# * Input : pos-train.txt: Training file (POS tagged text).
# * Output: pos-test.txt: Text File (to be POS Tagged).
#
#********************************************************************************************************************************************************

use strict;
use Data::Dumper qw(Dumper);
use List::Util qw(max); #Module that has the "max" function
use List::MoreUtils qw(first_index);
############################################################

my $isNumber = '\d+[\.,]*\d+'; #1 CD
my $beforeWordIsToBe = '(am| are | is| was| were |been )\w+ing\b'; #2 VBG
my $PRPZ_VBZ = '(she |he |it )\w+s\b'; #3 VBZ
my $isCompound = '\w+-\w+'; #4- JJ
my $determinants = '(the |a |an )\w*\s*\w+ied\b'; #5- JJ

#RULES: Derived from the Confusion Matrix

#1- CD: Track numbers
#2- VBG: If verb to be is before \w+ing\b
#3- VBZ: If word comes after NNP -> VBZ, PRP (she/he/it) + verb+s -> VBZ
#4- NN->JJ: if word is compound word1-word2 -> most likely to be JJ
#5- JJ: /(the|a|an) \w* \wied\b/i
############################################################

my %hash; #word_tag HASH

#1- Learn from POS-TAGGED TRAIN FILE
my @arrayTR;
my @word_tag;

my $token;

open(HANDLERTS, "<", "pos-test.txt") or die "Could Not Open file: pos-test.txt\n";
open(HANDLER_CLEAR_NEW, ">", "pos-test_wtih_tags.txt") or die "Could not create/open new file: pos-test_wtih_tags\n";
print HANDLER_CLEAR_NEW "";
close(HANDLER_CLEAR_NEW);
open(HANDLERTR, "<", "pos-train.txt") or die "Could Not Open file: pos-train.txt\n";
while(<HANDLERTR>)
{
	chomp;
	#1- Split by space to get (word/tag)
	@arrayTR = split(" ");

	
	# print "\nBEFORE: "; #>>>DEBUG
	# print join " | " , @arrayTR;
	# print " *\n";
	for (my $i=0; $i<scalar @arrayTR; $i++) #$token(@arrayTR)
	{
		$token = $arrayTR[$i];
		#2- Ensure no '[' or ']' are present
 		if($token =~m /^[\[\]]$/) 
		{
			#Remove from @array
			my $index_bracket = first_index { $_ eq $token } @arrayTR;
			splice @arrayTR, $index_bracket, 1; #offset:1 = delete:1
			$token = $arrayTR[$i]; #Update value of $token
		}

		#3- Ensure all $tokens in @array follow the patterns: (word/tag) - Remove ']'
		# $arrayTR[$i] =~ s/\](\w+)/$1/; #e.g.:  (]as/IN) -> (as/IN)
		if ($arrayTR[$i] =~ m/\](w+)/)
		{
			$arrayTR[$i]=~s/\](w+)/$1/; #e.g.:  (]as/IN) -> (as/IN)
			$token = $arrayTR[$i];
		}

		#4- Record occurances of (word/tag) in a hash{word}{tag} : #E.g. Love/VB = 2 and Love/NN = 3.
		@word_tag = split('/', $token);
		$hash{$word_tag[0]}{$word_tag[1]}++;
	}
	# print "\n=> AFTER: "; #>>>DEBUG
	# print join " | " , @arrayTR;
	# print "\n";
}
close(HANDLERTR);

#2- Tag words of TEST FILE using hash of tags
my @arrayTS;
my $maxtagValue;
my $winnerTagKey;

#For each word in the training data, assign it the POS tag that maximizes p(tag|word)= p(tag word) / p(word)
#Any word found in the test data but not in training data (ie an unknown word) is an NN,

open(HANDLERTS, "<", "pos-test.txt") or die "Could Not Open file: pos-test.txt\n";
open(HANDLER_mynew, ">>", "pos-test_wtih_tags.txt") or die "Could not create/open new file: pos-test_wtih_tags\n";

while(<HANDLERTS>)
{
	chomp;
	#Assign each word a tag (most likely one).
	#1- Tokenize Test-File
	@arrayTS = split(" ");

	# print "\nBEFORE: ";# >>>DEBUG
	# print join " | " , @arrayTS;
	# print " *\n";

	for (my $i=0; $i<scalar @arrayTS; $i++)
	{
		$token = $arrayTS[$i];
		
		#2- Ensure no '[' or ']' are present
		if($token =~m /^[\[\]]$/) 
		{
			#Remove from @array and go to loop
			
			# print ">$token<\n"; #>>>DEBUG
			my $index_bracket = first_index { $_ eq $token } @arrayTS;
			splice @arrayTS, $index_bracket, 1; #offset = 1
			$token = $arrayTS[$i]; #Update value of $token
		}
		#3- Choose the most likely tag to each $token <- assign
		if(exists $hash{$token}) #If the word exists from training data
		{
			#1. Find the word's tag (key-2) with the highest value
			$maxtagValue = max values %{$hash{$token}}; #int
			my @winners = grep { ${hash{$token}}{$_} eq $maxtagValue } keys %{$hash{$token}};
			$winnerTagKey = $winners[0];

			#2. Assign the tag to the word: BY deleting all the other tags
			%{$hash{$token}} = (); #Empty the word's tag hash
			${$hash{$token}}{$winnerTagKey} = $maxtagValue; #Replace with only the most likely tag
		}
		else #if not found -> NN
		{
			if($token=~/$isNumber/i) #1
			{
				$hash{$token}{"CD"}++;
				$winnerTagKey = "CD";
			}
			elsif($token=~/$beforeWordIsToBe/i) #2
			{
				#2- VBG: If verb to be is before \w+ing\b
				$hash{$token}{"VBG"}++;
				$winnerTagKey = "VBG";
			}
			elsif($token=~/$PRPZ_VBZ/i) #3
			{
				#3- VBZ: If word comes after NNP -> VBZ, PRP (she/he/it) + verb+s -> VBZ
				$hash{$token}{"VBZ"}++;
				$winnerTagKey = "VBZ";
			}
			elsif($isCompound=~/$PRPZ_VBZ/i || $isCompound=~/$determinants/i)
			{
				$hash{$token}{"JJ"}++;
				$winnerTagKey = "JJ";
			}
			else
			{
				$hash{$token}{"NN"}++;
				$winnerTagKey = "NN";
			}
		}
		#Write to new tagged file
		print HANDLER_mynew " ".$token."/".$winnerTagKey." ";
		#print word with tag to STDOUT:
		print " ".$token."/".$winnerTagKey." ";
	}
	# print "\n=> AFTER: "; #>>>DEBUG
	# print join " | " , @arrayTS;
	# print "\n";
}
close(HANDLER_mynew);
close(HANDLERTS);