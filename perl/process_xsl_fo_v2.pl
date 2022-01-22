
############# USAGE: ###############
#perl process_xsl_fo.pl 4141817.stage11.adjustNumbering_2.fo
####################################

#!/usr/bin/perl
use strict;
use warnings;
#use utf8::all; # either this or open the output file with '>:utf8'
use open qw(:std :utf8); # To get rid of "Wide character in print" warnig.
use XML::Twig;

#my $chapter_count = 0;
my $out;
my $read_in;
my @chapters_name;

my $input_fo_file = $ARGV[0]; # Take Input .fo file
my $output_chapters_directory = "Chapters_$input_fo_file"; 
system ("if exist \"$output_chapters_directory\" echo \"Directory already exists!\"");
system ("if not exist \"$output_chapters_directory\" mkdir $output_chapters_directory"); # Create output\topics directory

main();
#print @chapters_name;
remove_attributes();

sub main
{
	my $indented_input_fo_file = indented_fo($input_fo_file); #Ident the input file
	open(my $in, "$indented_input_fo_file") or die "Input: $!\n";
	while ($read_in = <$in>)
	{
		if($read_in =~ /master-reference="referencemanual-chapter"/g) #Look for chapters
		{	
			#$chapter_count++;
			my $chapter_name = shift(@chapters_name); #pop() will fetch from the last element. shift() will fetch from the first element.
			#print "$chapter_name \n";
			$chapter_name =~ s/[^a-zA-Z0-9\s+]//g; #Remove special and strange characters
			#print "$chapter_name \n";
			#$chapter_name =~ s/(Chapter\s*\d*)\s*(.*)/$2 $1/; # Change "Chapter 1 Overview" into "Overview Chapter 1". $1 is the first stored variable. $2 is the second.
			$chapter_name =~ s/(Chapter\s*\d*)\s*(.*)/$2/; # Change "Chapter 1 Overview" into "Overview"
			#print "$chapter_name \n";
			################Do not remove digit after chapter name. e.g. USB 2.0 and USB 3.0 It's only diff by number.################
			
			print "Processing $chapter_name\n";
			if($out)
			{
				print $out "\n</fo:root>";
				close($out) ;
				
			}
			#open($out, '>', "$output_chapters_directory/Chapter$chapter_count.xml") or die "Output: $!\n";
			open($out, '>', "$output_chapters_directory/$chapter_name.xml") or die "Output: $!\n";
			#print "Generated Chapter $chapter_count\n";
			#Added following print to fix "The prefix "fo" for element "fo:page-sequence" is not bound." oXygen error.
			print $out "<fo:root xmlns:meta=\"http://www.docato.com\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"
		xmlns:svg=\"http://www.w3.org/2000/svg\" xmlns:fo=\"http://www.w3.org/1999/XSL/Format\"
		xmlns:fsl=\"http://www.freescale.com/functions/xslt2\"
		xmlns:axf=\"http://www.antennahouse.com/names/XSL/Extensions\"
		xmlns:fox=\"http://xml.apache.org/fop/extensions\"
		font-selection-strategy=\"character-by-character\" hyphenate=\"false\"
		line-height-shift-adjustment=\"disregard-shifts\">
			";
			
		}
		print $out $read_in if($out);
	}
}


sub remove_attributes
{
	my @input_chapter_files = <$output_chapters_directory/*.xml>;
	my $removed_att_directory = "Removed_Attrib_Chapters_$input_fo_file"; 
	system ("if exist \"$removed_att_directory\" echo \"Directory already exists!\"");
	system ("if not exist \"$removed_att_directory\" mkdir $removed_att_directory"); # Create output\topics directory

	foreach my $input_chapter_file (@input_chapter_files)
	{
		
		print "File: $input_chapter_file \n";
		my $twig = XML::Twig->new();
		$twig->parsefile($input_chapter_file);
		my $file_name = (split(/\//,$input_chapter_file))[1];
		open(OUT, '>', "$removed_att_directory/removed_att_$file_name" ) or die "Couldn't open: $!";
		foreach my $chapters_tag ( $twig->get_xpath('//') ) 	
		{
			if ($chapters_tag->text eq '') 
			{
				$chapters_tag->delete;
			}
			$chapters_tag->del_atts;
		}
		print OUT $twig->sprint; 
		close(OUT);
	
	}
} 

 
sub indented_fo
{
	my ($unindented_fo_file) = @_; # my ($scalar_var) takes only first element of @_ array 
	my $twig = XML::Twig->new(     
		#output_filter => 'safe', # escapes all non-ascii characters (including accented ones)
		pretty_print => 'indented',                # output will be nicely formatted
		empty_tags   => 'html',                    # outputs <empty_tag />          
	);
	$twig->parsefile($unindented_fo_file);
	
	my $processed_twig = &process_twig($twig);
	
	open(my $out, '>', "indented_$unindented_fo_file") or die "Output: $!\n";
	#print $out $twig->sprint;  
	$processed_twig->print($out); #print idented output to file
	close($out);
	return("indented_$unindented_fo_file");
}
sub process_twig # All the processing on XSL FO file will be done here.
{
	my ($twig) = @_;
	########## Fetch chapters name #######
	#<fo:marker marker-class-name="chapt_head">Chapter 1​ Overview</fo:marker>
	foreach my $chapters_tag ( $twig->get_xpath('//fo:marker') ) # get each <register>
	{
		if($chapters_tag->att('marker-class-name') eq "chapt_head") 
		{
			push (@chapters_name,$chapters_tag->text) if ($chapters_tag->text ne ' ');
		}
	}
	foreach my $attributes ($twig->find_nodes('//*[@id]')) #select all tags with specified attributes
	{
	#if ($attributes->att('name'))
	#{
		$attributes->set_att('id' => ""); #Replace them with blank
	#}
	}
	foreach my $attributes ($twig->find_nodes('//*[@marker-class-name]')) #select all tags with specified attributes
	{
	#if ($attributes->att('name'))
	#{
		$attributes->set_att('marker-class-name' => ""); #Replace them with blank
	#}
	}
	foreach my $attributes ($twig->find_nodes('//*[@retrieve-class-name]')) #select all tags with specified attributes
	{
	#if ($attributes->att('name'))
	#{
		$attributes->set_att('retrieve-class-name' => ""); #Replace them with blank
	#}
	}
	foreach my $attributes ($twig->find_nodes('//*[@internal-destination]')) #select all tags with specified attributes
	{
	#if ($attributes->att('name'))
	#{
		$attributes->set_att('internal-destination' => ""); #Replace them with blank
	#}
	}
	 ### Delete section id: <fo:block id="" margin-right="5mm">27.4.2.93.4</fo:block>
	 foreach my $nodes ($twig->find_nodes('//fo:block[@margin-right="5mm"]'), $twig->find_nodes('//fo:basic-link[@internal-destination]'), $twig->find_nodes('//fo:block[@text-align="right"]'))
	 {
		$nodes->delete; 
	 }
	#print @chapters_name;
	######################################
	return $twig;
}
