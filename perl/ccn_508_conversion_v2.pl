############ Author : Niraj Gandhi (B49052) ###################
###############################################################


############### How to use this script?############################################

####################################################################################



use strict;
#use warnings;
use XML::Twig;
#my $curdir =`pwd`;
#print $curdir; 
my @input_xml_files = <input_regs/*.xml>;
#print @input_xml_files;
my $output_directory = "ccn_output_regs"; # create output directory for modified files.
system ("if not exist \"ccn_output_regs\" mkdir ccn_output_regs"); # Create output\topics directory
our @registers;
our @registers_desc;
our @registers_offset;
my $register_count = 0;
foreach my $input_xml_file (@input_xml_files) 
{
	
	my $twig = XML::Twig -> new ( twig_handlers => 			
										{ 'reference/title' => \&register_name,
										  'section/dl' => \&register_description,
										  'reference/shortdesc/ph' => \&register_offset
										}, 
								);
	$twig ->  parsefile ( $input_xml_file);
	
	$input_xml_file =~ s/.xml//;
	$input_xml_file =~ s/input_regs\///;
	my $regs_file_name = $input_xml_file.".regs";
	#chdir ($curdir);
	
    open(REGS_PPFE,">$output_directory/$regs_file_name") || die("Can't open the file.");
	my $register_id = $registers[$register_count];
	$register_id =~ s/[\(\s+-]/_/g;
	$register_id =~ s/,//g; # Remove ,
	print REGS_PPFE "<register_def name=\"$register_id\" id=\"$register_id\" width=\"64\">
          <brief_description>$registers[$register_count]</brief_description>
          <long_description>$registers_desc[$register_count]</long_description>
          <address offset=\"0x$registers_offset[$register_count]\"/>
          <reset_value value=\"0x0\"/> \n\n";
	foreach my $table ( $twig->get_xpath('//table') ) # get each <table>
	{
		# my $header = $table->prev_sibling->text;
		my @headers;

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
		
		foreach my $row ( $table->get_xpath("//row") ) #foreach my $row ( $table->get_xpath("tgroup/tbody/row") ) # get each <row> of one <table>
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
					
					print "This is binary \n" if -B $bit_reset;
					
					
					my $bit_access = $entries{'Access'};
					$bit_access =~ s/RAZ\/WI/ROZ/g;  
					my $bit_name = $entries{'Name'};
					#$bit_name =~ s/[\(\s+-]/_/g;
					#$entries{'Function'} =~ s/[‘’]/'/g;
					#print $bit_name;
					if ($bit_name =~ /-/)
					{
					print REGS_PPFE "<reserved_bit_field position=\"$bit_offset\" width=\"$bit_width\" access=\"$bit_access\">
             <reset_value value=\"0x$bit_reset\" override=\"true\"/>
          </reserved_bit_field>\n";
					}
					else
					{
					print REGS_PPFE "<bit_field name=\"$bit_name\" id=\"$bit_name\" position=\"$bit_offset\" width=\"$bit_width\" access=\"$bit_access\">
            <brief_description>$entries{'Name'}</brief_description>
            <long_description>
              <p>$entries{'Function'}$entries{'Description'}</p>
            </long_description>
            <reset_value value=\"0x$bit_reset\" override=\"true\"/>
            </bit_field>\n";
					
					}
					$bit_num = $bit_num + 1; 
					
				#}
				
			}
			else 
			{
				@headers = @row_entries;
			}
		}
	}
			
			
	print REGS_PPFE "</register_def>";

	close(REGS_PPFE);
	$register_count++;
}
#print "\n\n\n\n@registers \n";
#print "\n@registers_desc \n\n\n\n\n";    
#================================================== Subroutines =================================================
sub register_name {
    my ( $twig, $text_elt ) = @_; 
    #print $text_elt -> text; 
	push @registers, $text_elt -> text;
    $twig -> purge; 
}
sub register_description {
    my ( $twig, $text_elt ) = @_; 
    #print $text_elt -> text; 
	my $temp_reg_desc = $text_elt -> text;
	$temp_reg_desc =~ s/\bPurpose/<p>Purpose: /i;
	$temp_reg_desc =~ s/\bUsage constraints/<\/p><p>Usage constraints: /i;
	$temp_reg_desc =~ s/\bConfigurations/<\/p><p>Configurations: /i;
	$temp_reg_desc =~ s/\bAttributes.*//;#Remove all text after Attributes
	$temp_reg_desc = $temp_reg_desc."</p>";
	#print $temp_reg_desc;
	push @registers_desc, $temp_reg_desc;
    $twig -> purge; 
}
sub register_offset {
	my ( $twig, $text_elt ) = @_; 
    #print $text_elt -> text; 
	
	push @registers_offset, $text_elt -> text;
    $twig -> purge; 
}