#!/usr/bin/perl
use warnings;
use strict;

use XML::LibXML;
my $parser = XML::LibXML->new();
#my @input_xml_files = <input_regs/*.xml>;
#my $output_directory = "ccn_output_regs";
#my $file = shift;
# my $output_directory = "ccn_output_regs"; # create output directory for modified files.
# system ("if not exist \"ccn_output_regs\" mkdir ccn_output_regs"); # Create output\topics directory
my @input_xml_files = <*.xml>;

open (LOGFILE,">conversion_success.log");
print LOGFILE "Following files have been successfully converted:\n\n\n";
print LOGFILE "Old name --> New name\n\n";
for my $file (@input_xml_files)
{ 
	my $input_file_without_extension = $file;
	$input_file_without_extension =~ s/.xml//;
	my $dom = $parser ->parse_file($file);
	my $name_reference;
	my $name_concept;
	my $name_task;
	if ($dom->findvalue('/concept/title'))
	{
		$name_concept = $dom->findvalue('/concept/title');
		$name_concept =~ s/[\s+,-\/\[\]:\(\)]/_/g;
		
		rename $file, "$name_concept\_$input_file_without_extension.xml" or die "Can't rename $file.\n";
		print LOGFILE "$name_concept\_$input_file_without_extension\n";
	}
	elsif ($dom->findvalue('/reference/title'))
	{
		$name_reference = $dom->findvalue('/reference/title');
		$name_reference =~ s/[\s+,-\/\[\]:\(\)]/_/g;
		rename $file, "$name_reference\_$input_file_without_extension.xml" or die "Can't rename $file.\n";
		print LOGFILE "$name_reference\_$input_file_without_extension\n";
	}
	elsif ($dom->findvalue('/task/title'))
	{
		$name_task = $dom->findvalue('/task/title');
		$name_task =~ s/[\s+,-\/\[\]:\(\)]/_/g;
		rename $file, "$name_task\_$input_file_without_extension.xml" or die "Can't rename $file.\n";
		print LOGFILE "$name_task\_$input_file_without_extension\n";
	}
	else
	{
		print "Please look into $file. \n";
	}

}

#Create .log of the converted files

close (LOGFILE);

#if file already exists, throw error.