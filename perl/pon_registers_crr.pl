############ Author : Niraj Gandhi (B49052) ###################
###############################################################


############### How to use this script?############################################
# Remove <hsi> tag if present and add <xml>
# perl pon_registers_crr.pl gpon_onumac.xml > debug_gpon.txt

######################### Script cases #############################
#Run pon_inst_file_generation.pl on "modified_*" file to generate .inst file.
####################################################################################



use strict;
#use warnings;
use XML::Twig;
use Data::Dumper; 
use Data::Alias;



my @input_xml_files = $ARGV[0]; #("ngpon2_onumac_neches_pon_bom_2.xml");
my $reg_width = 32;
my $output_regs_directory = "regs"; # create output directory for modified regs files.
#my $output_inst_directory = "inst";
system ("if not exist \"regs\" mkdir regs"); # Create output\topics directory
#system ("if not exist \"inst\" mkdir inst"); # Create output\topics directory

	
	#my $inst_file_name = "pon_onumac_bg.inst";
	
	################################################### .inst file ####################################################
	#open(INST_CRR,">$output_inst_directory/$inst_file_name");
	
	# print INST_CRR "<?xml version=\"1.1\" encoding=\"UTF-8\"?>
# <crr:instance name=\"pon_mac\" xmlns:crr=\"http://apif.freescale.net/schemas/inst/1.2\"
  # xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
  # xsi:schemaLocation=\"http://apif.freescale.net/schemas/inst/1.2 http://apif.freescale.net/schemas/inst/1.2/inst.xsd\">
  # <creation_info author=\"\$Author: nxa18346 \$\" date=\"\$Date\$\"
    # revision=\"\$Revision\$\"
    # source=\"\$Source\$\"/>\n";
	
foreach my $input_xml_file (@input_xml_files) 
{
	my $modified_input_file = format_file($input_xml_file);
	print "Parsing ", $modified_input_file, "\n";
	print "partition_name,reg_parent_name,reg_name\n";
	my $twig = XML::Twig->new->parsefile ( $modified_input_file );
		
	$input_xml_file =~ s/.xml//;
	
	#print INST_CRR "<reg_instance name=\"$input_xml_file\" module=\"$input_xml_file\" nickname=\"Block\">\n";
	
	my $regs_file_name = $input_xml_file.".regs";
	##################################################### .regs file ###################################################
	open(REGS_CRR,">$output_regs_directory/$regs_file_name");

	print REGS_CRR "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<crr:UniversalDevice
  xsi:schemaLocation=\"http://apif.freescale.net/schemas/regs/1.3 http://apif.freescale.net/schemas/regs/1.3/regs.xsd\"
  xmlns:crr=\"http://apif.freescale.net/schemas/regs/1.3\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <creation_info author=\"\$Author: B49052 \$\" date=\"\$Date\$\"
    revision=\"\$Revision\$\"
    source=\"\$Source\$\"/>
  <GeneralPeriphery>
    <GeneralParameters>
      <instance_header>
        <instance_description>$input_xml_file</instance_description>
        <instance_long_description>
          <p>$input_xml_file Register_Definition </p>
         
        </instance_long_description>
        <!--<template_parameters>
          <include_template_parameters file=\"../params/gpon.paramdef\" format=\"XML\"/>          
        </template_parameters>-->
      </instance_header>
      <general_parameter_defs>
        <string_general_parameter name=\"peripheralType\" value=\"$input_xml_file\"
          description=\"Peripheral/Component Type\"/>
      </general_parameter_defs>
    </GeneralParameters>
    <register_defs>\n";
	#my $partition;
	
	my %partition_offsets;
	my $grand_parent;
	my $grand_offset;
	foreach my $partition ($twig->get_xpath('//Partition')) #get each <Partition>
	{
	  
      $partition_offsets{$partition->first_child('Name')->text} = $partition->first_child('AddressOffset')->text; #Associative array of all the partitions
	  #foreach my $part (keys (%partition_offsets))
	  #{
		#my $hex_offsets = sprintf("0x%08X", $partition_offsets{$part}); #32bits hex representation
		#print "Name: $part \nOffset: $partition_offsets{$part} \n\n";
	  #}
	  
	  if ($partition->children('Register')) #If partition has register then it should be processed. Else it is the grand partition
	  {
		#print $partition->first_child('Name')->text."\n";
	  
	  my $partition_name = $partition->first_child('Name')->text;
	  my $parent_partition_name = $partition->first_child('ParentName')->text;
	  
	  #printf ("Partition Name: $partition_name (0x%X)  Parent: $parent_partition_name (0x%X)\n",$partition_offsets{$partition_name},$partition_offsets{$parent_partition_name});
	  
	  my $physical_address;
	  $physical_address = int ($partition_offsets{$partition_name}) + int($partition_offsets{$parent_partition_name});
	  if ($grand_parent ne $parent_partition_name) #There are cases of Grand parent -> Parent -> Child e.g. DS_GEM -> GPON_DSGEM_DS_GEM -> GPON_DSGEM_pbit2dp_q_map
	  {
		$physical_address += int ($partition_offsets{$grand_parent});
	  }
	  # else
	  # {
	    # $physical_address = int ($partition_offsets{$partition_name}) + int($partition_offsets{$parent_partition_name});
	  # }
	  
	  my $hex_physical_offsets = sprintf("0x%08X", $physical_address); #32bits hex representation
	  #print "Name: $partition_name \nOffset: $hex_physical_offsets \n\n";
	  #print INST_CRR "<base_address base=\"$hex_physical_offsets\" space=\"$partition_name\"/>\n";
	  
	  my $partition_abstract= $partition->first_child('Abstract')->text;
	  $partition_abstract =~ s/&/and/g;
	  my $partitions_number = $partition->first_child('NumberOfPartitions')->text; #denotes registers instances
	  my $partitions_interval = $partition->first_child('IntervalBetweenPartitions')->text; #interval between two partitions
	  
	  print REGS_CRR "<address_block name=\"$partition_name\" byte_order=\"bigEndian\" lau=\"32\">
	  <brief_description>$partition_abstract</brief_description> \n";
      # print REGS_CRR "<long_description><p>Number of register instances: $partitions_number</p>
		# <p>Interval beetween the two instances: $partitions_interval</p></long_description> \n" if ($partitions_number > 1);
	  print REGS_CRR "  <base_address space=\"$partition_name\_base_address\"/>
        <bit_order order=\"lsb0\"/> \n"; 
		
	
		foreach my $register ( $partition->get_xpath('.//Register') ) # get each <Register> #Changed to './/Register' from '//Register' #You need a dot in the XPath expression, otherwise the search will start at the document root. 
		{
			#print $register, "\n";
			my $reg_name = $register->first_child('Name')->text;
			my $reg_parent_name = $register->first_child('ParentName')->text;
			
			################## Debug print to get partition name and parent name mismatch #######################
			print ("$partition_name,$reg_parent_name,$reg_name\n");
			#####################################################################################################
			
			my $reg_abstract= $register->first_child('Abstract')->text;
			my $bits_reg_description= $register->first_child('Description')->text;
			$bits_reg_description =~ s/#RTLPATH:.*//; # Remove text after and including #RTLPATH
			
			##### Grep each bit description and move them to appropriate bit fields #####
			# my %hash = split /Bit[0-9]:/, $bits_reg_description;
			# #my @each_bit_desc = split ('Bit',$bits_reg_description);
			# print Dumper \%hash;
			
			my $reg_address= $register->first_child('AddressOffset')->text;
			my $hex_reg_address = sprintf("0x%X", $reg_address);
			my $reg_access= $register->first_child('AccessMode')->text;
			my $reg_type= $register->first_child('Type')->text;
			$reg_type =~ s/&/and/g;
			$reg_width= $register->first_child('Size')->text;
			my $reg_reset= $register->first_child('InitializationValue')->text;
			
			my ($reg_description, @bit_description) = separate_bits_regs_description($bits_reg_description); 
			#print $bits_reg_description;
			
			################# Register array processing ######################
			if ($partitions_number > 1)
			{
			print REGS_CRR "	<register_array name=\"array_$partition_name\" size=\"$partitions_number\">
				<autoinc_address offset=\"0x0\" step=\"$partitions_interval\"/>
				 <int_iterator name=\"index\" from=\"0\"/>
				 <register_def name=\"$reg_name@[index]\" id=\"$reg_name@[index]\" width=\"$reg_width\">\n";
			}
			
			else
			{
				print REGS_CRR "        <register_def name=\"$reg_name\" id=\"$reg_name\" width=\"$reg_width\">\n";
			}
			#####################################################################
			
			print REGS_CRR "  <brief_description>$reg_name register</brief_description>
			  <long_description>
			  
				<p>$reg_description</p>
				<p>$reg_abstract</p>
				<p>Type: $reg_type</p>
			  </long_description>
			  <address offset=\"$hex_reg_address\"/>
			  <reset_value value=\"$reg_reset\"/>";
			  my $reg_field_position;
			  my $reg_field_width;
			  
			  ##################### Bit fields processing ###########################
			  foreach my $xml_field ($register->get_xpath('Field'))
			  {
				my $reg_field_name= $xml_field->first_child('Name')->text;
				my $reg_field_abstract= $xml_field->first_child('Abstract')->text;
				
				$reg_field_position= $xml_field->first_child('BitFieldOffset')->text;
				$reg_field_width= $xml_field->first_child('Size')->text;
				my $reg_field_access= $xml_field->first_child('AccessMode')->text;
				my $reg_field_type= $xml_field->first_child('Type')->text;
				$reg_field_type=~ s/&/and/g;
				my $reg_field_reset= $xml_field->first_child('InitializationValue')->text;
				
				
				########### Changing access types to NXP format #####################
				
				$reg_field_access =~ s/Read\/Write/RW/g ;
				$reg_field_access =~ s/Read Only/RO/g ;
				
				# $reg_field_desc =~ s/</[/g ; # removing <> from the description
				# $reg_field_desc =~ s/>/]/g ;
				
				###################################### Bits parsing ########################################
				#print $bits_reg_description. "\n";
				#my @matched = split ('Bits?\s+[0-9]-?', $bits_reg_description); #$bits_reg_description =~ /Bits?\s+$reg_field_position(.*?)Bit/s;
				#my @matched = split ('\n', $bits_reg_description);
				#my @matched = split ('Bit\s+[0-9]', $bits_reg_description);
				#alias @matched[1,2] = @matched[2,1];
				#print "$matched[0]\n$matched[1]\n\n";
				#print Dumper \@matched;
				#############################################################################################
				
					print REGS_CRR "
					<bit_field name=\"$reg_field_name\" id=\"$reg_field_name\" position=\"$reg_field_position\" width=\"$reg_field_width\" ";

					if ($reg_field_access =~ "Read/Clear on Write to 1")
					{
						print REGS_CRR "access=\"RW\" modified_write_values=\"oneToClear\">";
					}
					elsif ($reg_field_access =~ "Read/Set on Write to 1")
					{
						print REGS_CRR "access=\"RW\" modified_write_values=\"oneToSet\">";
					}
					else
					{
						print REGS_CRR "access=\"$reg_field_access\">";
					}
					
					print REGS_CRR "
						<brief_description/>
						<long_description>
						";
					foreach my $bit (@bit_description) #get relevant bit description according to bit number
					{
						if ($bit->{position} =~ /^$reg_field_position$/)
						{
							#print $bit->{description}."\n";
							print REGS_CRR "
								<p>$bit->{description}</p>
								";
						}
					}
					
					print REGS_CRR "
								<p>$reg_field_abstract</p>
							<!--<p>Type: $reg_field_type</p>-->
						</long_description>
						<reset_value value=\"$reg_field_reset\" override=\"true\"></reset_value>
					</bit_field>";
				
			   
			  }
			  if ((int($reg_field_position) + int($reg_field_width)) < 32)
			  {
				my $reserved_bit_position = int($reg_field_position) + int($reg_field_width);
				my $reserved_bit_width = 32 - int($reg_field_position) - int($reg_field_width);
				print REGS_CRR "
				<reserved_bit_field position=\"$reserved_bit_position\" width=\"$reserved_bit_width\" access=\"RU\"></reserved_bit_field>";
			  }
			  
			  
			  print REGS_CRR "
					</register_def> \n";
			print REGS_CRR "
					</register_array> \n" if ($partitions_number > 1);
		}	
	  print REGS_CRR "</address_block>\n";
	  }
	  else
	  {
		$grand_parent = $partition->first_child('Name')->text;
		$grand_offset += int($partition_offsets{$grand_parent});
	  }
	}
	print REGS_CRR "</register_defs>
  </GeneralPeriphery>
</crr:UniversalDevice>";

close(REGS_CRR);

# print INST_CRR "<parameter_values>
      # <parameter name=\"internal\" value=\"false\"/>
      # <parameter name=\"third_party_enablement_info\" value=\"false\"/>
    # </parameter_values>
    # <template_link file=\"../regs/$regs_file_name\"/>
  # </reg_instance>\n"
}
# print INST_CRR "\n</crr:instance>";	
# close (INST_CRR);

sub format_file
{

	my ($input_xml_file) = @_;

	open (IN_FILE,$input_xml_file);
	my @input_file = <IN_FILE>;


	for (my $line=0;$line<@input_file;$line++)#if (@old_config_file =~ /(?<=<uris>)(.*?)(?=<\/uris>)/g)  # Extracts text between <title> </title>
	{
				
				if ($input_file[$line] =~ /<\/Partition>/ && $input_file[$line+1] =~ /<Register>/)
				{
					$input_file[$line] = '';
					
				}
				if ($input_file[$line] =~ /<\/Field>/ && $input_file[$line+1] =~ /<Partition>/)
				{
					$input_file[$line] = "</Field>
	</Register>
	</Partition>
	";
					
				}
				if ($input_file[$line] =~ /<\/Field>/ && $input_file[$line+1] =~ /<Register>/)
				{
					$input_file[$line] = "</Field>
	</Register>
	";
					
				}
				if ($input_file[$line] =~ /<\/Register>/ && $input_file[$line+1] =~ /<Field>/ )
				{
					$input_file[$line] = '';
					
				}
				
	}
	#print OUT_FILE "</Register>";
		

	close(IN_FILE);
	my $output_file = "modified_".$input_xml_file;
	open (OUT_FILE,">$output_file");
	print OUT_FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xml>\n";
	foreach (@input_file)
	{
		 print OUT_FILE "$_";
	}
	print OUT_FILE "</Register>
	</Partition>";
	print OUT_FILE "\n</xml>";
	close (OUT_FILE);
	return ($output_file);

}

sub separate_bits_regs_description
{
	my ($description_in) = @_;
	#print $description_in;
	my @bits = ();
	my $description_overall = '';

	my $line_buffer = '';
	foreach my $line (split("\n", $description_in)) 
	{
	# if line
	  #  begins with optional white spaces
	  #  followed by "Bit" or "Bits"
	  #  followed by at least one white space
	  #  followed by at least one digit (we capture the digits)
	  #  followed by an optional sequence of optional white spaces, "-" or ":", optional white spaces and at least one digit (we capture the digits)
	  #  followed by an optional sequence of at least one white space and any characters (we capture the characters)
	  #  followed by the end of the line
	  if ($line =~ m/^\s*Bits?\s+(\d+)(?:\s*[-:]\s*(\d+))?(?:\s+(.*?))?$/) 
	  {
		my ($position_begin, $position_end, $description) = ($1, $2, $3);
		my $width;

		# if there already are bits we've processed
		if (scalar(@bits)) 
		{
		  # the lines possibly buffered belong to the bit before the current one, so append them to its description
		  $bits[$#bits]->{description} .= (length($bits[$#bits]->{description}) ? "\n" : '') . $line_buffer;
		  # and reset the line buffer to collect the additional lines of the current bit;
		  $line_buffer = '';
		}

		# $position_end is defined only if it was a "Bit n-m"
		# otherwise set it to $position_begin
		$position_end = defined($position_end) ? $position_end : $position_begin;

		$width = abs($position_end - $position_begin) + 1;

		# set description to the empty string if not defined (i.e. no description was found)
		$description = defined($description) ? $description : '';

		# push a ref to a new hash with the keys position, description and width into the list of bits
		push(@bits, { position => (sort({$a <=> $b} ($position_begin, $position_end)))[0], # always take the lower position
					  description => $description,
					  width => $width });
	  }
	  else 
	  {
		# it's not a bit pattern, so just buffer the line
		$line_buffer .= (length($line_buffer) ? "\n" : '') . $line;
	  }
	}
# anything still in the buffer must belong to the overall description
	$description_overall .= $line_buffer;

	#print("<Register>\n  <long_description>\n$description_overall\n  </long_description>\n");
	#foreach my $bit (@bits) 
	#{
	#	print("  <bit_field position=\"$bit->{position}\" width=\"$bit->{width}\">\n    <long_description>\n$bit->{description}\n    </long_description>\n  </bit_field>\n")
	#}
	return ($description_overall,@bits);
} 
