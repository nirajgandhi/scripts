############ Author : Niraj Gandhi (B49052) ###################
###############################################################


############### How to use this script?############################################
#perl iq_analog_adc_registers_crr.pl LS_registers.xml
####################################################################################
use strict;
use warnings;
use XML::Twig;
use utf8;

my $input_xml_file = $ARGV[0]; 
my $reg_width = 32;
my $output_regs_directory = "regs"; # create output directory for modified regs files.
system ("if not exist \"regs\" mkdir regs"); # Create output\topics directory
my $twig = XML::Twig->new->parsefile ( $input_xml_file );
$input_xml_file =~ s/.xml//;
my $regs_file_name = $input_xml_file.".regs";

open(REGS_CRR,">$output_regs_directory/$regs_file_name") or die "Couldn't open: $!";
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
	
foreach my $bodydiv ($twig->get_xpath('//bodydiv')) #Get each address_block
{  
	my $address_block_name = $bodydiv->first_child('section')->text;
	my $address_block_description = defined $bodydiv->first_child('p') ? $bodydiv->first_child('p')->text : '';
	$address_block_name =~ s/^[2.\d+]//g; #Remove section number
	$address_block_name =~ s/^[3.\d+]//g; #Remove section number
	$address_block_name =~ s/^\s+|\s+$//g; #Remove leading and trailing whitespace
	$address_block_name =~ s/\s+/_/g; #Replace whitespace between words with _
	
	print REGS_CRR "<address_block name=\"$address_block_name\" byte_order=\"bigEndian\" lau=\"32\">
	  <long_description>$address_block_description</long_description>
		<base_address space=\"$address_block_name\"/>
        <bit_order order=\"lsb0\"/> \n"; 
	
	foreach my $table ( $bodydiv->get_xpath('.//table') ) #Get each register
	{
		my @thead_row_entries;
		foreach my $thead_row ($table->get_xpath('.//thead/row') ) #Get each register name, access, default value and offset
		{
			@thead_row_entries = map { $_->text =~ s/\n\s+//rg; } $thead_row->children; # remove 'linefeed and whitespace' (s/\n\s+//gr) #Get all the entries
		}
		my $register_name = $thead_row_entries[0];
		my $register_default_value;
		my $register_access;
		if ($thead_row_entries[1] =~ /DEF/) #if the entry has both access and default value
		{
			($register_access, $register_default_value) = split(/,\s*DEF:\s*/,$thead_row_entries[1]);
		}
		else
		{
			$register_access = $thead_row_entries[1];
			$register_default_value = "0x0";
		}
		$register_access=~ s/^\s+//; #Remove whitespace before the string
		my $register_offset = $thead_row_entries[2];
		print REGS_CRR "<register_def name=\"$register_name\" id=\"$register_name\" width=\"32\">
						  <brief_description>$register_name</brief_description>
						  <long_description/>
						  <address offset=\"$register_offset\"/>
						  <reset_value value=\"$register_default_value\"/> \n";
						  
		my %long_bit_description;
		my $bit_name;
		my $bit_description;
		my $bit_offset;
		my $bit_width;
		my $bit_reset;
		my $more_rows = 0;
		my $row_count = 0;
		foreach my $tbody_row ($table->get_xpath('.//tbody/row')) #Get each bit
		{
			$row_count = $row_count+1;
			my @tbody_row_entries = map { $_->text =~ s/\n\s+//rg; } $tbody_row->children; # remove 'linefeed and whitespace' (s/\n\s+//gr) #Get all the entries
			my @headers;
			my %row_entries;
			@headers = ('Bits','Bit_name','Bit_description');
			$bit_name = $tbody_row_entries[1] if (defined($tbody_row_entries[1]) ne '');
			if (@tbody_row_entries == 4) 
			{
				#DEF column available
				splice @headers, 2, 0, 'Bit_reset'; #Add new element at 2nd position of the array
				@row_entries{@headers} = @tbody_row_entries;
				$row_entries{'Bit_reset'} =~ s/DEF:\s*//;
				$bit_reset =  $row_entries{'Bit_reset'};
				$more_rows = $tbody_row->first_child('entry')->att('morerows'); #Get such entries which has multiple cells 
			}
			elsif(@tbody_row_entries == 3)
			{
				#DEF column not available
				@row_entries{@headers} = @tbody_row_entries;
				$bit_reset = "0x0";
				$more_rows = $tbody_row->first_child('entry')->att('morerows');
			}
			else
			{
				#multiple rows in bit description
				$long_bit_description{$bit_name} .= "<p>".$tbody_row->first_child('entry')->text."</p>"; #Append each entry
				#next;
				$more_rows = $more_rows - 1; #Decrement more_rows till it becomes zero. It ensures that all the multiple cells have been parsed.
			}
			if ($row_entries{'Bits'}) #If Bit is not empty
			{
				$long_bit_description{$bit_name} = defined ($long_bit_description{$bit_name}) ? $long_bit_description{$bit_name} : '';  
				$bit_description = $row_entries{'Bit_description'};
				
				$row_entries{'Bits'} =~ s/[\[\]]//g; # remove [] from this text
				if($row_entries{'Bits'} =~ /:/) # e.g. 3:2
				{
					my $bit_width_temp;
					($bit_width_temp, $bit_offset) = split(':',$row_entries{'Bits'});
					$bit_width = int($bit_width_temp) - int($bit_offset) + 1;				
				}
				else # e.g. 24
				{
					$bit_offset = $row_entries{'Bits'};
					$bit_width =  1;				
				}
			}
			if ($more_rows == 0) # Entry which has only single cell or entry which has been parsed by decrementing more_rows to 0
			{
				if ($row_count==1) #First row of the table 
				{
					my $reserved_bit_offset = int($bit_offset)+int($bit_width);
					if ( $reserved_bit_offset < 32) # Add missing reserved bits
					{
						my $reserved_bit_width = 32 - $reserved_bit_offset;
						print REGS_CRR "<reserved_bit_field position=\"$reserved_bit_offset\" width=\"$reserved_bit_width\" access=\"RU\"></reserved_bit_field> \n";
					}
				}
				$bit_name =~ s/\s+//g;
				$bit_reset=~ s/\s+//g;
				print REGS_CRR "<bit_field name=\"$bit_name\" id=\"$bit_name\" position=\"$bit_offset\" width=\"$bit_width\" access=\"$register_access\">
									<brief_description>$bit_description</brief_description>
									<long_description>$long_bit_description{$bit_name}</long_description>
									<reset_value value=\"$bit_reset\" override=\"true\"></reset_value>
								  </bit_field>";
			}
		}
		print REGS_CRR "\n </register_def> \n";
	}
	print REGS_CRR "\n </address_block>\n"; 
	 
}
	
print REGS_CRR "\n</register_defs>
				  </GeneralPeriphery>
				</crr:UniversalDevice>\n";
close REGS_CRR;
 
#### End of the script ####
