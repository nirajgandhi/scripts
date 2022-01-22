#!/usr/bin/perl -w

#Run this script after running infocenter_status.pl.
# This script checks for internal file in the output.txt comparing all with map file. If found, it is removed from output.txt and renamed to modified_output_with_no_internal.txt.

open(OUTPUT,"output.txt") or die ("Can't open output.txt. \n") ;
open(MOD_OUTPUT,">modified_output_with_no_internal.txt") or die("Can't ceate modified_output_with_no_internal.txt. \n"); #contains no internal files.
#open(MAP,"map_cpc.xml") or die("Can't open the map file. \n");

#@map = <MAP>;
@output = <OUTPUT>; # Read output.txt
$map_file = <map_*>; # Lists map file in present directory.

foreach $file (@output) # Read each file from output.txt.
		{
			chomp($file);
			open(MAP,"$map_file") or die("Can't open the map file. \n"); # Read map file.
	
	
			while($read_map = <MAP>)
			{	
				chop($read_map);
				if ($read_map =~ /$file/) # If file from output.txt is there in map file.
				{
					#$flag1 = $file." found.";
					#print("$flag1 \n");
					if (($read_map =~ /"internal"/) or ($read_map =~ /"non_cust"/) or ($read_map =~ /"editor_notes"/) or ($read_map =~ /"editorial"/)) # If any internal properties are there, do nothing.
					{
						#$flag2 = "internal file found.";
						#print("$flag2 \n");
						#next;
					}
					else # Write to modified_output_with_no_internal.txt which contains no internal files.
					{
						print MOD_OUTPUT "$file \n";
					}
				}
			}
			#seek( MAP, 0, 0 );
			close(MAP);
	
		}	
#close(MAP);
close(MOD_OUTPUT);
close(OUTPUT);