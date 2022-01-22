
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

my $input_fo_file = $ARGV[0]; # Take Input .fo file
my $indented_input_fo_file = indented_fo($input_fo_file); #Ident the input file

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
	
	############ Remove unnecessary attributes value to avoid in diff ###########
	#//@id, //@marker-class-name, //@retrieve-class-name
	foreach my $attributes ($twig->find_nodes('//*[@id]'), $twig->find_nodes('//*[@marker-class-name]'), 
	$twig->find_nodes('//*[@retrieve-class-name]'), $twig->find_nodes('//*[@internal-destination]'), $twig->find_nodes('//fo:page-number-citation[@ref-id]'),
	$twig->find_nodes('//fo:table-column[@column-width]')) #select all tags with specified attributes
	{
	#if ($attributes->att('name'))
	#{
		#Make sure it changes if attribute is available. Currently it is adding new attirbutes.
		$attributes->set_att('id' => "", 'marker-class-name' => "", 'retrieve-class-name' => "", 'internal-destination' => "", 'ref-id' => "", 'column-width' => ""); #Replace them with blank
		# $attributes->set_att('id' => "") if ($attributes->att('id'));
		# $attributes->set_att('marker-class-name' => "") if ($attributes->att('marker-class-name'));
		# $attributes->set_att('retrieve-class-name' => "") if ($attributes->att('retrieve-class-name'));
		# $attributes->set_att('internal-destination' => "") if ($attributes->att('internal-destination'));
		# $attributes->set_att('ref-id' => "") if ($attributes->att('ref-id'));
		# $attributes->set_att('column-width' => "") if ($attributes->att('column-width'));
	#}
	}
	
	### Delete nodes and comment it.
	#fo:block text-align="right"
	foreach my $nodes ($twig->find_nodes('//fo:block[@text-align="right"]')) #select all tags with specified attributes
	{
		$nodes->insert_new_elt( before => '#COMMENT', $nodes->outer_xml); # insert_new_elt will add new element. #COMMENT means a comment. outer_xml will fetch text with the whole element.
		$nodes->delete; 
	}
	# foreach my $nodes ($twig->find_nodes('//fo:block[@internal-destination]'), $twig->find_nodes('//fo:basic-link[@internal-destination]')) #select all tags with specified attributes
	# {
		# $nodes->insert_new_elt( before => '#COMMENT', $nodes->outer_xml); # insert_new_elt will add new element. #COMMENT means a comment. outer_xml will fetch text with the whole element.
		# $nodes->delete; 
	# }
	
	#############################################################################
	return $twig;
}
