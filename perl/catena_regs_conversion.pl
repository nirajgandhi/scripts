############ Author : Niraj Gandhi (B49052) ###################
###############################################################


############### How to use this script?############################################

####################################################################################



use strict;
#use warnings;
use XML::Twig;

my $input_xml_file = "VEN_memory_definition.xml";

my $output_directory = "regs"; # create output directory for modified files.
system ("if not exist \"regs\" mkdir regs"); # Create output\topics directory

	print "Parsing ", $input_xml_file, "\n";
	my $twig = XML::Twig->new->parsefile ( $input_xml_file );
	# my $reg_bits = 16; # Length of register
	# my $reg_access = "RW"; # Register access
	# my $reg_bitorder = "increment"; # Register bit order

	
	
	$input_xml_file =~ s/.xml//;
	my $regs_file_name = $input_xml_file.".regs";
	open(REGS_VENOM,">$output_directory/$regs_file_name");

	print REGS_VENOM "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<crr:UniversalDevice
  xsi:schemaLocation=\"http://apif.freescale.net/schemas/regs/1.3 http://apif.freescale.net/schemas/regs/1.3/regs.xsd\"
  xmlns:crr=\"http://apif.freescale.net/schemas/regs/1.3\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
  <creation_info author=\"\$Author: B49052 \$\" date=\"\$Date: Wed May 17 2017 \$\"
    revision=\"\$Revision: 1.0 \$\"
    source=\"\$Source: /sync/vault/15136/sv/Projects/dng_docs/sata_doc/spec/crr/regs/sata.regs.rca \$\"/>
  <GeneralPeriphery>
    <GeneralParameters>
      <instance_header>
        <instance_description>VENOM</instance_description>
        <instance_long_description>
          <p>Venom_TRX_Register_Definition </p>
         
        </instance_long_description>
        <!--<template_parameters>
          <include_template_parameters file=\"../params/venom.paramdef\" format=\"XML\"/>          
        </template_parameters>-->
      </instance_header>
      <general_parameter_defs>
        <string_general_parameter name=\"peripheralType\" value=\"VENOM\"
          description=\"Peripheral/Component Type\"/>
      </general_parameter_defs>
    </GeneralParameters>
    <register_defs>
      <address_block name=\"VENOM\" byte_order=\"bigEndian\" lau=\"16\">
        <base_address/>
        <bit_order order=\"lsb0\"/> \n"; # bit order as per the Venom excel sheet

	foreach my $register ( $twig->get_xpath('//register') ) # get each <register>
	{
		#print $register, "\n";
		my $reg_name = $register->att('name');
		my $reg_width= $register->att('width');
		 my $reg_address= $register->att('bbp_address');
		#my $reg_address= $register->att('address');
        #print "$reg_name \n";
		print REGS_VENOM "        <register_def name=\"$reg_name\" id=\"$reg_name\" width=\"$reg_width\">
          <brief_description>$reg_name register</brief_description>
          <long_description>
            <p></p>
          </long_description>
          <address offset=\"$reg_address\"/>
          <!--<reset_value value=\"0x0\"/>-->";
		  
		  foreach my $xml_field ($register->get_xpath('field'))
		  {
			my $reg_field_name= $xml_field->att('name');
			#print "$reg_field_name \n";
			my $reg_field_position= $xml_field->att('bit');
			my $reg_field_width= $xml_field->att('width');
			my $reg_field_access= $xml_field->att('access');
			my $reg_field_reset= $xml_field->att('reset');
			my $reg_field_desc= $xml_field->att('comment');
			########### Changing access types to NXP format #####################
			#$reg_field_access =~ s/\///g if ($reg_field_access =~ "R/W");
			$reg_field_access =~ s/\bR\/W\b/RW/g ;
			$reg_field_access =~ s/\bR\/WS\b/RW/g ;
			$reg_field_access =~ s/\bR\b/RO/g ;
			$reg_field_access =~ s/\bRS\b/RO/g ;
			$reg_field_access =~ s/\bRR\b/RO/g ;
			
			#$reg_field_access =~ s/\bCR\b/RW/g ;
			
			$reg_field_desc =~ s/</[/g ; # removing <> from the description
			$reg_field_desc =~ s/>/]/g ;
			
			
			if(uc ($reg_field_name) eq "NOT USED" )
			{
				print REGS_VENOM "
				<reserved_bit_field position=\"$reg_field_position\" width=\"$reg_field_width\" access=\"RU\">
				<reset_value value=\"undefined\"></reset_value>
				</reserved_bit_field>";
			}
			else
			{
				print REGS_VENOM "
				<bit_field name=\"$reg_field_name\" id=\"$reg_field_name\" position=\"$reg_field_position\" width=\"$reg_field_width\"";
			
			
			##################### Handle CR, SR and SC bit access. ###########################
				if ($reg_field_access =~ /\bCR\b/)
				{
					print REGS_VENOM " access=\"RW\" read_action=\"clear\">";
				}
				elsif ($reg_field_access =~ /\bSR\b/)
				{
					print REGS_VENOM " access=\"RW\" read_action=\"set\">";
				}
				elsif ($reg_field_access =~ /\bSC\b/)
				{
					print REGS_VENOM " access=\"RW\" modified_write_values=\"clear\">";
				}
				else
				{
					print REGS_VENOM " access=\"$reg_field_access\">";
						
				}
			################################################################################
			
				print REGS_VENOM "
					<brief_description/>
					<long_description>
						<p>$reg_field_desc</p>
					</long_description>
					<reset_value value=\"0x$reg_field_reset\"></reset_value>
				</bit_field>";
			}
		   
		  }
		  
		  
		  print REGS_VENOM "
                </register_def> \n";
		
	}	

	
	print REGS_VENOM "</address_block>
    </register_defs>
  </GeneralPeriphery>
</crr:UniversalDevice>";

	close(REGS_VENOM);
