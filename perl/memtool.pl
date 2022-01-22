
##############################################
#Author: Niraj Gandhi (niraj.gandhi@nxp.com)
#This script displays bit-by-bit mapping of value provided and register information of given register name.
#Date of submission: June 2018
##############################################

use strict;
use warnings;
use Getopt::Long qw(:config no_auto_abbrev); #configure to force the full name of the string used as option.
use XML::Twig;
use Text::ANSITable;
use Pod::Usage;
use Text::Wrap qw(wrap);
#use Math::BigInt;
no warnings 'portable';  # Support for 64-bit ints required #Hides warning "Hexadecimal number > 0xffffffff non-portable"
# use Text::Table;
# use Text::Table::Any;
# use Text::SimpleTable::AutoWidth;
# use Text::TabularDisplay;
 
# don't forget this if you want to output utf8 characters
binmode(STDOUT, ":utf8");

=head1 USAGE

    perl memtool.pl [options] [value]
	                                            
    Options:                                                                       
                                              
        -help, -h           Brief help message
        -address            Register absolute memory offset in hex with '0x' prefix
        -endian             Set 'little' or 'big' endian, default is little.
        -iregs              SoC .iregs file which contains details of all the SoC registers
        -map_value          Specify register value needs to be mapped
        -reg                Show the detailed regsister information. -address and -map_value arguments cannot be used with -reg.
	    

=head1 DESCRIPTION

#This will desplay when -verbose => 2
...

=cut


#@ARGV = qw(--address 0x08380040 --map_value 0x12345678 --iregs top_lx2.iregs --reg CS1_BNDS); #set fixed argument for testing
my $endianness = "little"; #default little
my $show_reg_switch=0; #if -reg swtich is used

main();

sub main{
    my ($address, $iregs_file, $register, $map_value, $help);

    GetOptions(
	#set switches to be used with running this script
        'address=s'        => \$address,
		'map_value=s'        => \$map_value,		
		'iregs=s' => \$iregs_file,
        'reg=s'    => \$register,
		'endian=s'    => \$endianness,
		'help|h' => \$help,
    ) or pod2usage(q(-verbose) => 1);
pod2usage(q(-verbose) => 1) if $help;       #usage(); 
	
	#if($help)
	#{
	#	usage();
	#}
	#else
	#{
		if (defined $address && defined $iregs_file && defined $map_value) 
		{
			chomp($address);
			chomp($map_value);
			chomp($iregs_file);
			if (defined $register)
			{
				print STDERR "Cannot use -reg with -address and -map_value arguments. Use -help or -h option to see usage.";
				#usage();
				exit;
			}
			else
			{
				if ($address !~ /^0[x|X][0-9a-fA-F]+$/ || $map_value !~ /^0[x|X][0-9a-fA-F]+$/)
				{
					print "Please enter the valid hex value with '0x' prefix.";
					exit;
				}
				# if (defined $endianness)
				# {
					chomp ($endianness);
					if (($endianness ne "big") && ($endianness ne "little"))
					{
						print "Please enter the endinness either 'big' or 'little'.";
						exit;
					}	
				# }
				 
				get_register_details($address, $iregs_file,$map_value);
			}
		}
		elsif (defined $register && defined $iregs_file )
		{
			chomp($register);
			chomp($iregs_file);
			if (defined $address || defined $map_value)
			{
				print STDERR "Cannot use -address and -map_value arguments with -reg. Use -help or -h option to see usage.";
				#usage();
				exit;
			}
			else
			{
				$show_reg_switch=1;
				show_register($register,$iregs_file);
			}
		}
		else
		{
			print STDERR "Missing arguments. Use -help or -h option to see usage.";
			#usage();
		}
	#}	
	
    #die "THE END";
}

sub show_register
{
	my( $register, $iregs_file ) = @_;
    open (IREGS,"$iregs_file") || die "\nCan't open '$iregs_file'. Please check file location or file name.\n\n"; # Adding \n at the end, results die without the location info (at .\memtool.pl line 132)
	my $twig = XML::Twig->new->parsefile ( $iregs_file );
	my $reg_found = 0;
	foreach my $instance ($twig->get_xpath('//instance/register_defs/address_block')) # get each <instance>
	{
		#my $abs_add = $instance->first_descendant('absolute_address');
		my $block_address = $instance->first_descendant('absolute_address')->att('base');
				
		foreach my $reg_def ($instance->get_xpath('.//register_def'))
		{
			#my $reg_add = $reg_def->first_descendant('address');
			my $reg_offset = $reg_def->first_descendant('address')->att('offset');
			
			
			my $reg_name = $reg_def->att('name');
			if (lc $register eq lc $reg_name) #string case insensitive comparison
			{
				$reg_found = 1;
				#my $reg_bit_order = $reg_def->first_child('bit_order')->att('order');
				my $reg_reset = $reg_def->first_child('reset_value')->att('value');
				my $reg_abs_add = sprintf "0x%08X",hex($block_address) + hex($reg_offset);
				
				get_register_details($reg_abs_add,$iregs_file,$reg_reset);
			}
			else
			{
				#print "Register not found. Check register name.";
				#exit;
			}
		}	
	}
	if($reg_found == 0)
	{
		print "Register not found. Please check register name.";
	}
	close(IREGS);
}
sub get_register_details 
{
    my ($address, $iregs_file, $map_value) = @_;
    open (IREGS,"$iregs_file") || die "Can't open '$iregs_file'. Please check file location or file name.\n\n";
	my $twig = XML::Twig->new->parsefile ( $iregs_file );
	my $reg_found = 0;
	foreach my $instance ($twig->get_xpath('//instance/register_defs/address_block')) # get each <instance>
	{
		#my $endinness = $instance->att('byte_order');
		my $block_address;
		foreach my $abs_add ($instance->get_xpath('.//absolute_address'))
		{
		 $block_address = $abs_add->att('base');
		 
		}
		foreach my $reg_def ($instance->get_xpath('.//register_def'))
		{
			my $reg_add = $reg_def->first_descendant('address');
			my $reg_offset = $reg_add->att('offset');
			
			if (hex($address) == hex($block_address) + hex($reg_offset))
			{
				#my $temp_1 = hex($block_address) + hex($reg_offset);
				#printf("Matched: 0x%08X\n",$temp_1);
				$reg_found = 1;
				my $reg_name = $reg_def->att('name');
				my $reg_width = $reg_def->att('width');
				
				my @bits_position; #(@reserved_bits_position, @reserved_bits_width);
				my (%bits_name, %bits_width, %bits_access, %bits_brief_desc, %bits_long_desc, %bits_fields, %bits_reset, %bits_reset_override);
				
				my $reg_brief_desc = $reg_def->first_child('brief_description')->text;
				
				my $node = $reg_def->first_child('long_description');
				if ($node->children('table')) #If table found, replace it with it's title
				{
					foreach my $table_instance ($node->get_xpath('.//table')) 
					{
							my $table_title = $table_instance->first_child('title')->text;
							my $update = " See \"".$table_title."\" table for more information. ";
							$table_instance->set_text($update);
							#$node = $node->insert_new_elt('last_child', $tag);
					}
				}
				
				my $reg_long_desc = sprintf format_text($node); #Add new line after each paragraph
				#my $reg_long_desc = $node->text;
				#$reg_long_desc =~ s/[\r\n\s]+/ /g; #remove redundant white spaces
				
				my $reg_reset = $reg_def->first_child('reset_value');
				my $reg_bit_order = $reg_def->first_child('bit_order')->att('order');
				# printf("Reset: 0x%08X",$reg_reset);
			
				foreach my $bit_field ($reg_def->get_xpath('.//bit_field'))
				{
					my ($bit_name, $bit_position, $bit_width, $bit_access) = ($bit_field->att('name'), $bit_field->att('position'), $bit_field->att('width'), $bit_field->att('access'));
					
					my $bit_reset_element = $bit_field->first_child('reset_value');
					my $bit_reset = defined($bit_reset_element) ? $bit_reset_element->att('value') : '';
					my $bit_reset_override = defined($bit_reset_element) ? $bit_reset_element->att('override'): '';
			
					my $bit_brief_desc = $bit_field->first_child('brief_description'); #first_descendant was picking tag under <bit_field_value>
					$bit_brief_desc = defined($bit_brief_desc) ? $bit_brief_desc->text : ''; #make sure $bit_brief_desc is defined
					
					my $bit_long_desc = $bit_field->first_child('long_description');
					$bit_long_desc = defined($bit_long_desc) ? $bit_long_desc->text : '';
					
					push @bits_position, $bit_position;
					$bits_name{$bit_position} = $bit_name;
					$bits_width{$bit_position} = $bit_width;
					$bits_access{$bit_position} = $bit_access;
					$bits_brief_desc{$bit_position} = $bit_brief_desc; 
					$bit_long_desc =~ s/[\r\n\s]+/ /g; #remove redundant white spaces
					$bits_long_desc{$bit_position} = $bit_long_desc;
					$bits_reset{$bit_position} = $bit_reset;
					$bits_reset_override{$bit_position} = $bit_reset_override;
					
					my $bit_fields = '';
					foreach my $bit_field_values ($bit_field->get_xpath('.//bit_field_value'))
					{
						my $field_value  = $bit_field_values->att('value');
						my $field_brief_desc = $bit_field_values->first_child('brief_description');
						$field_brief_desc = defined($field_brief_desc) ? $field_brief_desc->text : '';
						my $field_long_desc = $bit_field_values->first_child('long_description');
						$field_long_desc = defined($field_long_desc) ? $field_long_desc->text : '';
						
						$bit_fields = $bit_fields.$field_value.":".$field_brief_desc.$field_long_desc." ";
					}
					#$bit_fields = defined($bit_fields) ? $bit_fields : ''; #make sure $bit_fields is defined
					$bit_fields =~ s/\s+/ /g; #remove redundant white spaces
					$bits_fields{$bit_position} = $bit_fields;
				}
				foreach my $reserved_field ($reg_def->get_xpath('.//reserved_bit_field'))
				{
					my ($reserved_bit_position, $reserved_bit_width, $reserved_bit_access) = ($reserved_field->att('position'), $reserved_field->att('width'), $reserved_field->att('access'));
					#push @reserved_bits_position, $reserved_bit_position;
					#push @reserved_bits_width, $reserved_bit_width;
					push @bits_position, $reserved_bit_position;
					$bits_width{$reserved_bit_position} = $reserved_bit_width;
					$bits_name{$reserved_bit_position} = 'Reserved';
					$bits_access{$reserved_bit_position} = $reserved_bit_access;
					$bits_brief_desc{$reserved_bit_position} = ''; 
					$bits_long_desc{$reserved_bit_position} = '';
					$bits_fields{$reserved_bit_position} = '';
					
				}
				#you cannot pass two arrays to a subroutine without loosing the information which entry belongs to which array. 
				#a subroutine call flattens array contents to a long list. best way usually is to pass references of the arrays. 
				show_mapping($address, $reg_name, $reg_width, $reg_brief_desc, $reg_long_desc, 
				\@bits_position, 
				\%bits_name, \%bits_width, \%bits_access, \%bits_brief_desc, \%bits_long_desc, \%bits_fields, \%bits_reset, \%bits_reset_override, $map_value,$reg_bit_order);
			}
			else
			{
				#print "Register not found.";
				#exit;
			}
		}
	}
	if ($reg_found == 0)
	{
		print "Register not found. Please enter valid register absolute address.";
	}
	close(IREGS);
	
}
sub show_mapping
{
	my ($reg_address, $reg_name, $reg_width, $reg_brief_desc, $reg_long_desc, 
	$bits_position,
	$bits_name, $bits_width, $bits_access, $bits_brief_desc, $bits_long_desc, $bits_fields,  $bits_reset, $bits_reset_override, $map_value,$reg_bit_order) = @_;
	
	#printf("%064B\n", hex($map_value));
	#print $map_value;
	if ($endianness eq "big")
	{
		my $unchanged_map_value = $map_value;
		$map_value = change_endinness($unchanged_map_value,$reg_width);
	}
	#printf($map_value);
	#my $dec = Math::BigInt->new($map_value);
	#printf("%064B", int($dec));
	my $binary_map_value = sprintf("%064B", hex($map_value)); #64B caters 64/32/16/8 bits registers #Use %032B --> 32bits binary representation with leading 0s
	
	#my $temp = substr $binary_map_value, -32,8; #extract bitfield reset value
	#$binary_map_value<<=2;
	#$D3 = ( $num >> 0 ) & ( 1 << 4 ) - 1;  # 4 bits starting at bit 0
	#my $temp = ( $binary_map_value >> 0 ) & ( 1 << 2 ) - 1;
	
	print "\n\n\n";
	print "============== $reg_name ($reg_address): $reg_brief_desc ================\n";
	
	$Text::Wrap::columns = 100; #100 characters long
	print wrap('', '', $reg_long_desc)."\n\n"; #wrap(initial_tab,subsequent_tab,text)
	#print "\n$reg_long_desc \n\n";
	
	#my  $table_51 = Text::Table->new("Bit Name\n-----","Range\n-----","Mapped Value\n-----","Brief Desc\n-----","Long Desc\n-----","Fields value\n-----");
	# my $t1 = Text::SimpleTable::AutoWidth->new();
	# my  $table_51 = Text::Table->new();
	#my $table = Text::TabularDisplay->new("Bit Name","Range","Mapped Value","Brief Desc","Long Desc","Fields value");
	# $t1->captions( ['Bit Name', 'Range', 'Mapped Value', 'Brief Desc', 'Long Desc', 'Fields value']);
	# my $table_51 = Text::Table->new(
    # {is_sep => 1, title => '| ', body => '| '},
    # "Bit Name",
    # {is_sep => 1, title => ' | ', body => ' | '},
    # "Range",
	# {is_sep => 1, title => ' | ', body => ' | '},
    # "Mapped Value",
	# {is_sep => 1, title => ' | ', body => ' | '},
    # "Brief Desc",
	# {is_sep => 1, title => ' | ', body => ' | '},
    # "Long Desc",
	# {is_sep => 1, title => ' | ', body => ' | '},
    # "Fields value",
    # {is_sep => 1, title => ' |', body => ' |'},
	# );
	my $table = Text::ANSITable->new;
	#$table->use_utf8(0);
	# $table->use_box_chars(0);
	# $table->use_color(0);
	# $table->border_style('Default::single_ascii');
	#$table->show_header(0);
	#$table->cell_vpad(2); #add vertical space to each cell
	$table->columns( ['Bit Name', 'Range', 'Value', 'Access', 'Description', 'Fields value']);
	foreach my $bit_position (sort { $a <=> $b } @$bits_position) #sort bit positions numerically
	{
		my $bit_range = int($bit_position) + int($bits_width->{$bit_position}) - 1;
		my $bit_map_value = substr ($binary_map_value, -($bit_range+1),$bits_width->{$bit_position});
		
		#"$chek{$key}" tells Perl to look for a hash named %chek, but you want to use a scalar reference to a hash, $chek. This can be done by writing either $chek->{$key} or $$chek{$key}.
		
		my $string_range; 
		$string_range = $bit_range."-".$bit_position if ($reg_bit_order eq "lsb0");
		$string_range = $bit_position."-".$bit_range if ($reg_bit_order eq "msb0");
		$string_range = $bit_position if ($bit_range eq $bit_position);
		#print ("$bit_map_value \n");
		my $hex_map_value = "0x".bin2hex($bit_map_value);
		#print "$hex_map_value\n";
		if ($show_reg_switch && defined $bits_reset_override->{$bit_position} && $bits_reset_override->{$bit_position} eq "true") #only if show_register sub routine called. Should not take the override value when we need to map value.
		{
			$hex_map_value = $bits_reset->{$bit_position};
		}
		#$t1->row( '$bits_name->{$bit_position}', '$string_range', '$hex_map_value', '$bits_brief_desc->{$bit_position}', '$bits_long_desc->{$bit_position}', '$bits_fields->{$bit_position}' );
		#my @split_a = split "@@",$bits_fields->{$bit_position};
		#$bits_fields->{$bit_position} =~ s/@@@@/\n/g;
		
		$table->add_row(
                       ["$bits_name->{$bit_position}", 
					   "$string_range",
					   "$hex_map_value",
					   "$bits_access->{$bit_position}",
					   "$bits_brief_desc->{$bit_position} $bits_long_desc->{$bit_position}", #\n$bits_long_desc->{$bit_position}
					   "$bits_fields->{$bit_position}"]
                       );    # a record of data
		$table->add_row_separator;
        		
	}
	print $table->draw;
	print "\n\n\n";
	# $t1 = $table_51;
	#$table_51->add(' ');   #ADD AN EMPTY Record
	#print $tb->rule('-', '+');					
}

sub bin2hex {

    my $bin = shift;

    # Make input bit string a multiple of 4
    $bin = substr("0000",length($bin)%4) . $bin if length($bin)%4;

    my ($hex, $nybble) = ("");
    while (length($bin)) {
        ($nybble,$bin) = (substr($bin,0,4), substr($bin,4));
        $nybble = eval "0b$nybble";
        $hex .= substr("0123456789ABCDEF", $nybble, 1);
    }
    return $hex;
}

sub change_endinness
{
	#my $hex = "00030478";
	my ($hex,$reg_width) = @_;
	#print $reg_width;
	$hex =~ s/^0[X|x]//;
	$hex = sprintf "%016s",$hex if $reg_width==64;
	$hex = sprintf "%08s",$hex if $reg_width==32;
	$hex = sprintf "%04s",$hex if $reg_width==16;
	#print $hex;
	$hex = sprintf "%02s",$hex if $reg_width==8;
	my @c = split('', $hex);
	my $bits='';
	my $changed_hex = $hex if @c==2; #8-bit
	$bits = pack("v*", unpack("n*", pack("H*", $hex))) if @c==4; #(16-bit)
	$bits = pack("V*", unpack("N*", pack("H*", $hex))) if @c==8; #(32-bit)
	$changed_hex = sprintf("0x%s", unpack("H*", $bits)) if (@c==4 || @c==8); 
	$changed_hex = sprintf("0x%s", join '', (@c)[14,15,12,13,10,11,8,9,6,7,4,5,2,3,0,1]) if (@c==16); #This method can be used for 16/32 bits as well.
	
	return ($changed_hex);
}
sub format_text 
{
#XML Twig converts "<p>abc<br>xyz</p>" to "abcxyz". Means, it just removes child tag and 
#doesn't replace it with white space or new line. This subroutine will replace such elements into new lines.

        my($el) = @_;
        my $r = "";
        for my $n ($el->descendants_or_self) 
		{
            if ($n->is_text) 
			{
                $r .= $n->trimmed_text;
            } 
			elsif ("p" eq $n->gi || "ul" eq $n->gi || "li" eq $n->gi || "table" eq $n->gi) 
			{
                $r .= "\n\n";
            }
			
			#else
			#{
			#	$r .= $n->trimmed_text;
			#}
        }
        $r;
}
#sub usage
#{
	#say STDERR "Usage: $0 ...";   # full usage message
    #exit;
	 
#}
__END__
