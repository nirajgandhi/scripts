########## USAGE ##########
#  perl pon_inst_file_generation.pl gpon_onumac.xml


use strict;
#use warnings;
use XML::Twig;

my $input_xml_file=	"modified_".$ARGV[0];
my $file_parent = $ARGV[0];
$file_parent =~ s/\.[^.]+$//; # remove extension
#my $file_parent = "gpon_onumac"; #change this as per file

my $twig = XML::Twig->new->parsefile ( $input_xml_file );
	
	my $grand_offset;
	my $physical_address;
	my $parent_off;
	my %partition_offsets;
	
#my $temp_1 = $twig->get_xpath('Partition');
#my $temp_2;# = $temp_1->first_descendant('ParentName');	
my $iteration = 0;

	foreach my $partition ($twig->get_xpath('//Partition')) #get each <Partition>
	{
	$iteration++;
	#$file_parent = $partition->first_descendant('ParentName')->text if $iteration==1 ; #Get parent name from first iteration
	#print $file_parent;
	 my $partition_name = $partition->first_child('Name')->text;
	 $partition_offsets{$partition_name} = $partition->first_child('AddressOffset')->text; #Associative array of all the partitions
	 
     my $parent_partition_name = $partition->first_child('ParentName')->text;
	 #print "$partition_name,$partition_offsets{$partition_name},$parent_partition_name\n";
	 if ($parent_partition_name eq $file_parent && !$partition->children('Register')) #start of new block
	 {
		#$grand_offset = $partition_offsets{$partition_name};
		$physical_address = 0;
		$parent_off = 0;
	 }
	 elsif($parent_partition_name eq $file_parent && $partition->children('Register')) 
	 #e.g. GPON_DS_TC_portID_lookup_table, GPON_DS_DBG_table which have parent 'gpon_onumac' and also have registers
	 {
		my $hex_physical_offsets = sprintf("0x%08X", $partition_offsets{$partition_name}); #32bits hex representation
		print  "<base_address base=\"$hex_physical_offsets\" space=\"$partition_name\_base_address\"/>\n";
	 }
	 else
	 {
		$parent_off += int ($partition_offsets{$parent_partition_name}); #add all parents offset
		$physical_address =  int ($partition_offsets{$partition_name}) + $parent_off ;
		if ($partition->children('Register')) #If partition has register then it should be processed. Else it is the grand partition
		{
			 my $hex_physical_offsets = sprintf("0x%08X", $physical_address); #32bits hex representation
			  #print "Name: $partition_name \nOffset: $hex_physical_offsets \n\n";
			  print  "<base_address base=\"$hex_physical_offsets\" space=\"$partition_name\_base_address\"/>\n";
		}
	 }
	}
	