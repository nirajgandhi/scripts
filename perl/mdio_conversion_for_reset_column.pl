############ Author : Niraj Gandhi (B49052) ###################
###############################################################


############### How to use this script?############################################

####################################################################################



use strict;
#use warnings;
use XML::Twig;

my @input_xml_files = <*.xml>;
# print @input_xml_files;
my $output_directory = "dil"; # create output directory for modified files.
system ("if not exist \"\dil\" mkdir \dil"); # Create output\topics directory

foreach my $input_xml_file (@input_xml_files) 
{
	print $input_xml_file, "\n";
	my $twig = XML::Twig->new->parsefile ( $input_xml_file );

	my $reg_bits = 32; # Length of register
	my $reg_access = "RW"; # Register access
	my $reg_bitorder = "decrement"; # Register bit order

	
	my $regs_file_name = "regs_".$input_xml_file;
	$input_xml_file =~ s/.xml//;
	open(REGS_PPFE,">$output_directory/$regs_file_name");

	foreach my $table ( $twig->get_xpath('//table') ) # get each <table>
	{
		# my $header = $table->prev_sibling->text;
		my @headers;

		###############################  Register specifications ####################################################
		
		my $reg_line;#= $table->prev_sibling->text; # extract value from <b></b> # Each table, we assume that the previous sibling element is the header
		
		(my $reg_name,my $address_reset) = split(':\s+',$reg_line); # Split register name and address/reset texts
		#print $reg_name, $address_reset, "\n";
		$address_reset =~ s/(\)|\()//g; # Remove () from the line
		#print $address_reset, "\n";
		(my $address,my $reset) = split('\s+',$address_reset); # Split address and reset
		(my $address_txt,my $address_val) = split('=',$address); # Split "Address" and its value 
		(my $reset_txt,my $reset_val) = split('=',$reset); # Split "Reset" and its value
		
		#print $address_val, $reset_val, "\n";
		$address_val =~ s/X/x/g; # Replace 'X' with 'x'
			
		# print REGS_PPFE "<register id=\"$reg_name\">\n";
		# print REGS_PPFE "<registerName>$reg_name</registerName>\n";
		# print REGS_PPFE "<registerNameMore>
			# <registerNameFull></registerNameFull>
			# <registerBriefDescription/>
		# </registerNameMore>
		# <registerBody>
			# <registerDescription>
			# </registerDescription>
			# <registerProperties>
				# <registerPropset>
					# <registerBitsInLau></registerBitsInLau>
					# <addressOffset>$address_val</addressOffset>
					# <registerSize>$reg_bits</registerSize>
					# <registerAccess>$reg_access</registerAccess>\n";
		if (($reset_val eq " ") || ($reset_val eq "32'h0") || ($reset_val eq "16'h0") || ($reset_val =~ /^*b0$/) || ($reset_val =~ /^*h0$/) || ($reset_val =~ /^*b00$/) || ($reset_val eq "NA") || ($reset_val eq "0"))
		{
			#print REGS_PPFE "<registerResetValue>0x0000_0000</registerResetValue>\n";
		}	
		else
		{
			#print REGS_PPFE "<registerResetValue>$reset_val</registerResetValue>\n";
		}	
		
		# print REGS_PPFE "<bitOrder>$reg_bitorder</bitOrder>
				# </registerPropset>
			# </registerProperties>
		# </registerBody>\n";
		#################################################################################################################
		
		################################## Bit fields ####################################################################
		
		my $bit_num = 1; # bit number
		my $bit_width_temp = 0; 
		my $bit_offset = 0; # bit offset
		my %entries;
		my $row_count = 0; # row counter
		my $reserved_bit_offset;
		my $reserved_bit_width;
		my $prev_bit_offset = 0;
		my $prev_bit_width_temp = 0;
		my $prev_colon = 0;
		my $prev_single = 0;
		
		foreach my $row ( $table->get_xpath("tgroup/tbody/row") ) # get each <row> of one <table>
		{
			# my %entries;
			$row_count = $row_count+1;
			# print $row_count, "\n";
			
			
			my @row_entries = map { $_->text =~ s/\n\s+//rg; } $row->children; # remove 'linefeed and whitespace' (s/\n\s+//gr) 
			if (@headers) 
			{
				
				# my $bit_width_temp;
				# my $bit_offset;
				my $bit_width; # bit width
				
				@entries{@headers} = @row_entries;
				#foreach my $field (@headers) 
				#{
					# print "$field: $entries{$field}\n";
					if($entries{'Bits'} =~ /:/) # e.g. 3:2
					{
						$prev_bit_width_temp = $bit_width_temp;
						$prev_bit_offset = $bit_offset;
						# print $reg_name," Prev prev_bit_width_temp: ", $prev_bit_width_temp, " Prev prev_bit_offset: ", $prev_bit_offset;
						$prev_colon = 1 - $prev_single;
						#$prev_single = 0;
						($bit_width_temp, $bit_offset) = split(':',$entries{'Bits'});
						$bit_width = int($bit_width_temp) - int($bit_offset) + 1;
						# print " Now bit_width_temp: ",$bit_width_temp, " Now bit_offset: ",$bit_offset, "\n";
						
					}
					else # e.g. 24
					{
						$prev_bit_offset = $bit_offset;
						$prev_bit_width_temp = $bit_width_temp;
						# print $reg_name, " Prev prev_bit_width_temp: ", $prev_bit_width_temp," Prev prev_bit_offset: ", $prev_bit_offset;
						$prev_single = 1 - $prev_colon;
						#$prev_colon = 0;
						($bit_width_temp, $bit_offset) = (0,$entries{'Bits'});
						$bit_width = int($bit_width_temp) + 1;
						# print  " Now bit_width_temp: ",$bit_width_temp," Now bit_offset: ",$bit_offset,"\n";
					}
					
					my $bit_reset = $entries{'Reset Value'};
					my $bit_access = $entries{'Type'};
					#$bit_access =~ s/\///g; # remove / 
					my $bit_name = $entries{'Register Name'};
					$bit_name =~ s/[\(\s+-]/_/g;
					#$entries{'Description'} =~ s/[‘’]/'/g;
					#print $bit_name;
					print REGS_PPFE "<bit_field name=\"$bit_name\" id=\"$bit_name\" position=\"$bit_offset\" width=\"$bit_width\" access=\"$bit_access\">
            <brief_description>$entries{'Register Name'}</brief_description>
            <long_description>
              <p>$entries{'Description'}</p>
            </long_description>
            <!--<reset_value value=\"$bit_reset\"/>-->
            </bit_field>\n";
					
					
					$bit_num = $bit_num + 1; 
					
				#}
				
			}
			else 
			{
				@headers = @row_entries;
			}
			
			
			# ############################################# Add Reserved bits for first and middle entries ######################################
			
			# if ($row_count == 2) # first row is for headers (Field, OFFSET, ...)
			# {
				# #if($entries{'OFFSET'} =~ /:/)
				# #{
					# if ((int($bit_offset)) > 0)
					# {
						# $bit_num = $bit_num + 1;
						# $reserved_bit_width = int($bit_offset);
						# print REGS_PPFE "<bitField id=\"$reg_name\_bit$bit_num\">
						# <bitFieldName>—</bitFieldName>
						# <bitFieldBriefDescription/>
						# <bitFieldBody>
							# <bitFieldDescription>
								# <p></p>
							# </bitFieldDescription>
							# <bitFieldProperties>
								# <bitFieldPropset>
									# <bitWidth>$reserved_bit_width</bitWidth>
									# <bitOffset>0</bitOffset>
									# <bitFieldAccess>RU</bitFieldAccess>
									# <bitFieldRadix/>
								# </bitFieldPropset>
							# </bitFieldProperties>
						# </bitFieldBody>
					# </bitField>\n";
						
					# }
				# #}
				# # else
				# # {
					
				# # }
			
				
				
			# }
			# if ($row_count > 2) # else
			# {
				# #print $reg_name," ", $row_count," ", $prev_colon , "\n";
				# my $res_bit_width;
				# my $res_bit_offset;
				
				# #if ($prev_colon == 1)
				# #{
					# if ((int($prev_bit_width_temp) > 0) && (((int($prev_bit_width_temp)) + 1) < (int($bit_offset)))) #if (((int($prev_bit_width_temp)) + 1) > (int($bit_offset)))# if (((int($prev_bit_width_temp)) + 1) != (int($bit_offset)))
					# {
						# $bit_num = $bit_num + 1;
						# $res_bit_width = int($bit_offset) - $prev_bit_width_temp -1;
						# $res_bit_offset = $prev_bit_width_temp + 1;
						# print REGS_PPFE "<bitField id=\"$reg_name\_bit$bit_num\">
						# <bitFieldName>—</bitFieldName>
						# <bitFieldBriefDescription/>
						# <bitFieldBody>
							# <bitFieldDescription>
								# <p></p>
							# </bitFieldDescription>
							# <bitFieldProperties>
								# <bitFieldPropset>
									# <bitWidth>$res_bit_width</bitWidth>
									# <bitOffset>$res_bit_offset</bitOffset>
									# <bitFieldAccess>RU</bitFieldAccess>
									# <bitFieldRadix/>
								# </bitFieldPropset>
							# </bitFieldProperties>
						# </bitFieldBody>
					# </bitField>\n";
					
					# }
				# #}
				# #if ($prev_single == 1)
				# #{print $reg_name," Row count: ", $row_count," prev_single ", $prev_single , "\n\n";
					# if ((int($prev_bit_width_temp) == 0) && ((int($prev_bit_offset)+1) < (int($bit_offset)))) # if ((int($prev_bit_offset)+1) != (int($bit_offset)))
					# {
						# $bit_num = $bit_num + 1;
						# $res_bit_width = int($bit_offset) - $prev_bit_offset -1;
						# $res_bit_offset = $prev_bit_offset + 1;				
						# print REGS_PPFE "<bitField id=\"$reg_name\_bit$bit_num\">
						# <bitFieldName>—</bitFieldName>
						# <bitFieldBriefDescription/>
						# <bitFieldBody>
							# <bitFieldDescription>
								# <p></p>
							# </bitFieldDescription>
							# <bitFieldProperties>
								# <bitFieldPropset>
									# <bitWidth>$res_bit_width</bitWidth>
									# <bitOffset>$res_bit_offset</bitOffset>
									# <bitFieldAccess>RU</bitFieldAccess>
									# <bitFieldRadix/>
								# </bitFieldPropset>
							# </bitFieldProperties>
						# </bitFieldBody>
					# </bitField>\n";
					# }
				# #}
				
			
			# }
			
			# $bit_num = $bit_num + 1;
			# ##################################################################################################################################
			
		}
		#print "----\n";
		
		
		# ################################### Add Reserved bits for last entry ###################################################################
		# if (((int($bit_width_temp)) < ($reg_bits-1)) && (int($bit_offset) != ($reg_bits-1))) # Considering OFFSET cases --> 26, 31, 31:29, 3:2
		# {
			# # my $reserved_bit_offset;
			# # my $reserved_bit_width;
			
			# if($entries{'Bit'} =~ /:/)
			# {
				# $reserved_bit_offset = int($bit_width_temp) + 1 ;
				# $reserved_bit_width = ($reg_bits-1) - int($bit_width_temp) ;
			# }
			# else
			# {
				# $reserved_bit_offset = int($bit_offset)+1;
				# $reserved_bit_width = ($reg_bits-1) - int($bit_offset);
			# }
			
			# print REGS_PPFE "<bitField id=\"$reg_name\_bit$bit_num\">
			# <bitFieldName>—</bitFieldName>
			# <bitFieldBriefDescription/>
			# <bitFieldBody>
				# <bitFieldDescription>
					# <p></p>
				# </bitFieldDescription>
				# <bitFieldProperties>
					# <bitFieldPropset>
						# <bitWidth>$reserved_bit_width</bitWidth>
						# <bitOffset>$reserved_bit_offset</bitOffset>
						# <bitFieldAccess>RU</bitFieldAccess>
						# <bitFieldRadix/>
					# </bitFieldPropset>
				# </bitFieldProperties>
			# </bitFieldBody>
		# </bitField>\n";
			
		# }
		# #################################################################################################################
		
		##################################################################################################################
		
		
		#print REGS_PPFE "</register>\n";
		
		
	}
	# print REGS_PPFE "\n</addressBlock>
		# </memoryMap>
	# </sidsc-component>\n";

	close(REGS_PPFE);
}