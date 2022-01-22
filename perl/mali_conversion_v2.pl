############ Author : Niraj Gandhi (B49052) ###################
###############################################################


############### How to use this script?############################################

####################################################################################

use strict;
use open ':std', ':encoding(UTF-8)'; # To remove 'Wide character in print' error
#use warnings;
use XML::Twig;

my @input_xml_files = <input_regs/*.xml>;
#print @input_xml_files;
my $output_directory = "mali_output_regs"; # create output directory for modified files.
system ("if not exist \"mali_output_regs\" mkdir mali_output_regs"); # Create output\topics directory
foreach my $input_xml_file (@input_xml_files) 
{
	
	print "Parsing ", $input_xml_file, "\n";
	my $twig = XML::Twig->new->parsefile ( $input_xml_file );
	
	$input_xml_file =~ s/.xml//;
	$input_xml_file =~ s/input_regs\///;
	my $regs_file_name = $input_xml_file.".regs";
	
    open(REGS_PPFE,">$output_directory/$regs_file_name") || die("Can't open the file.");
	
	foreach my $table ($twig->get_xpath('//table')) # get each <table>
	{
		my $register_name = $table->first_child('title')->text;
		my $reg_desc = $table->first_child('desc');
		my $reg_offset = $reg_desc->first_child('codeph')->text;
		
		#my $reg_offset_hex = printf("0x%08s", $reg_offset); #32bits hex representation
		#print $reg_offset."\n";
		$register_name =~ s/[^[:ascii:]]//g; #remove non-ascii
		my @headers;
		my $register_id = $register_name;
	    $register_id =~ s/[\(\s+-]/_/g;
		$register_id =~ s/_+/_/g; #replace multiple _ with single _
		
	    $register_id =~ s/,//g; # Remove ,
		#print $regs_file_name."\n";
		#print $table."\n\n";
		#print $register_id."\n";
	    print REGS_PPFE "<register_def name=\"$register_id\" id=\"$register_id\" width=\"32\">
          <brief_description>$register_name</brief_description>
          <long_description></long_description>
          <address offset=\"$reg_offset\"/>
          <reset_value value=\"0x0\"/> \n\n";
		  
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
		
		# foreach my $row ( $table->get_xpath("tgroup/thead/row") )
		# {
			# my @row_entries = map { $_->text =~ s/\n\s+//rg; } $row->children; # remove 'linefeed and whitespace' (s/\n\s+//gr) 
			# @headers = @row_entries;
		# }
		
		foreach my $row ( $table->get_xpath(".//row") ) #$table->first_descendant('row') OR #foreach my $row ( $table->get_xpath("tgroup/tbody/row") ) # get each <row> of one <table>
		{
			$row_count = $row_count+1;
			
			my @row_entries = map { $_->text =~ s/\n\s+//rg; } $row->children; # remove 'linefeed and whitespace' (s/\n\s+//gr) 
			if (@headers) 
			{
				
				my $bit_width; # bit width
				
				@entries{@headers} = @row_entries;
				#foreach my $field (@headers) 
				#{
					$entries{'Bits'} =~ s/[\[\]]//g; # remove [] from this text
					#print "$entries{'Bits'}\n";
					
					
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
					
					my $bit_reset = $entries{'Reset value'};
					#$bit_reset = s/-/0/g;
					#print "This is binary \n" if -B $bit_reset;
					my $bit_access;
					if ($entries{'Access type'})
					{
						$bit_access = $entries{'Access type'};
					}
					else
					{
						my $reg_access = $table->first_child('desc')->text;
						$reg_access =~ m/access type:\s+(.*?)?$/; 
						$bit_access = $1;
						#print $bit_access."\n";
					}
					
					my $bit_name = $entries{'Name'};
					
					if ($bit_name =~ /-/)
					{
					#Assigned 0 reset value to reserved bits
					print REGS_PPFE "<reserved_bit_field position=\"$bit_offset\" width=\"$bit_width\" access=\"RU\">
             <reset_value value=\"0x0\" override=\"true\"/>
          </reserved_bit_field>\n";
					}
					else
					{
						print REGS_PPFE "<bit_field name=\"$bit_name\" id=\"$bit_name\" position=\"$bit_offset\" width=\"$bit_width\" access=\"$bit_access\">
            <brief_description>$entries{'Name'}</brief_description>
            <long_description>
              <p>$entries{'Usage'}</p>
            </long_description>
            <reset_value value=\"0x$bit_reset\" override=\"true\"/>
            </bit_field>\n";
					
					}
					$bit_num = $bit_num + 1; 	
			}
			else 
			{
				@headers = @row_entries;
			}
		}
		#print $row_count."\n";
		print REGS_PPFE "</register_def>\n";		
	}
	close(REGS_PPFE);
}

