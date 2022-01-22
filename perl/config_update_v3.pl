# This script modifies the config file.


#$viewID=0; 
#$version=0;


############################################ USAGE ##########################################
#############################################################################################

#### Please make sure that config file, input file and script are in the same folder. 
#### Command to be executed:   <name_of_perl script> <config_file> <input_csv_file>

####################################### Taking arguments from comand line######################
################################################################################################


$num_args = $#ARGV + 1;
	if ($num_args != 2)			# quit unless we have two command-line args
	{
		print "\n Usage: <script_file_name> <config_file_name> <input_csv_file_name> \n";
		exit;
	}
 
# we got two command line args, they are the config_file name and input_file name

$config_file = $ARGV[0];
$input_file = $ARGV[1];
$num_of_new_files = 0;
$num_of_input_files = 0;
$num_of_files_updated = 0;
my $temp_directory = "dump"; # create output directory for modified files.
system ("if not exist \"\dump\" mkdir \dump"); # Create output\topics directory

#======================================== Main =====================================================#
#use warnings;
use File::Copy;
extract_tags();
file_viewID();
old_allstatic_formatting();
input_file_version();
new_config();
modify_AllStaticResources();
modify_StaticResources();
combine_all_files();
#manually_add_new_files();

#====================================================================================================

#================================================== Subroutines ============================================#


################################## Open and read old config file and extract other tags and <uris> to get viewID.##################################
sub extract_tags 
{
	
	open(OLD_CONFIG,"$config_file")|| die("Can't open the file $config_file.");

	open (URIS,">$temp_directory/uris.xml")|| die("Can't create the file uris.xml.");
	open(OLD_CONFIG_staticMMO,">$temp_directory/old_staticMMOResource.xml")|| die("Can't create the file old_staticMMOResource.xml.");
	open(OLD_CONFIG_allstatic,">$temp_directory/old_allStaticResources.xml")|| die("Can't create the file old_allStaticResources.xml.");
			

	while (<OLD_CONFIG>)
	{
			   
				
				print URIS "$_" if (/<uris>/ .. /<\/uris>/); 			# Extracts text between tags <uris> and </uris>
				
				
				if (/<staticResources>/ .. /<\/staticResources>/)
				{
					if (/<allStaticResources>/ .. /<\/allStaticResources>/)
					{
						print OLD_CONFIG_allstatic "$_" ;		#Prints text between tags <allStaticResources> and </allStaticResources>
					}
					else
					{
						print OLD_CONFIG_staticMMO "$_" ;		#Prints text between tags <staticResources> and </staticResources>
					}	
				} 
	}	
	close(OLD_CONFIG_allstatic);
	close(OLD_CONFIG_staticMMO);
	close(URIS);

	close(OLD_CONFIG);
}
####################################################################################################################################

######################### Split file_name and viewID in URIS ##############################################################################
sub file_viewID
{
	open(READ_URIS,"$temp_directory/uris.xml")|| die("Can't open the file uris.xml.");

	while ($read_READ_URIS = <READ_URIS>)
	{
		if( $read_READ_URIS =~ /<uris>/ || $read_READ_URIS =~ /<\/uris>/ ) 
		{
			
			next;
		}
		else
		{
		
			@viewID_file = split('\s+',$read_READ_URIS);		## spliting the URIS with white spaces and store it in an array
			$file_n = $viewID_file[1];				## the first element of array will be file name	
			$viewid{$file_n} = $viewID_file[0];			## the zeroth element will be ID
					
		}

	}

	close(READ_URIS);
}

####################################################################################################################################

######################### All static Resource file formatting for better file handling##############################################################################

sub old_allstatic_formatting
{
	
open(READ_OLD_ALLSTATIC, "$temp_directory/old_allStaticResources.xml")|| die("Can't read the file old_allStaticResources.xml.");
open(FORMAT_OLD_ALLSTATIC, ">$temp_directory/formatted_allStaticResources.xml")|| die("Can't create the file formatted_allStaticResources.xml.");
{
	while($read_READ_OLD_ALLSTATIC = <READ_OLD_ALLSTATIC>)
	{
		
		$read_READ_OLD_ALLSTATIC =~ s/<allStaticResources>/<allStaticResources>\n/g;
		#$read_READ_OLD_ALLSTATIC =~ s/<\/allStaticResources>//g;
		$read_READ_OLD_ALLSTATIC =~ s/\n+/ /g;
		$read_READ_OLD_ALLSTATIC =~ s/\s+/\n/g;
		print  FORMAT_OLD_ALLSTATIC $read_READ_OLD_ALLSTATIC; 
	
		}
	
	}	

close(FORMAT_OLD_ALLSTATIC);
close(READ_OLD_ALLSTATIC);

}

#######################################################################################################
#######################################################################################################

############################# Open list of modified files and separate file_name and version.###################################

sub input_file_version
{	
open (MOD_FILES,"$input_file")|| die "Couldn't open $input_file.";

while ($read_MOD_FILES = <MOD_FILES>)
{
	
		@file_and_version = split(',',$read_MOD_FILES);		## split input CSV by the ',' character and store it into an array
		$file_and_version[0] =~ s/\s+//;			## removing spaces in input file name, if any
		$file = $file_and_version[0];				## zeroth element is file name
		$version{$file} = $file_and_version[1];			## creating the associative array of versions wrt file name
		$version{$file} =~ s/\n//;
					
}
close(MOD_FILES);
}

####################################################################################################################################
#######################Creating new AllStatic tags to replace with old AllStatic tags####################################################

sub new_config
{
#open(INPUT_staticMMO,">input_staticMMOResource.xml")|| die("Can't create the file input_staticMMOResource.xml.");
open(NEW_FILE_ADDED,">new_files_added.txt") || die("Can't create the file new_files_added.txt");
open(INPUT_allstatic,">$temp_directory/input_allStaticResources.xml")|| die("Can't create the file input_allStaticResources.xml.");

foreach $file_name (keys(%version)) 
{
	$num_of_input_files = $num_of_input_files + 1;
	if($viewid{$file_name})
	{
		$num_of_files_updated = $num_of_files_updated + 1;
		if ($file_name =~ /\images\//)
		{
			#print INPUT_staticMMO  "<staticMMOResource language=\"eng\" variant=\"default\" version=\"$version{$file_name}\" id=\"$file_name\.svg\"></staticMMOResource> \n";
			print INPUT_allstatic "MMO__$viewid{$file_name}__eng__default__$version{$file_name}\n";
		}
		else
		{
			#print INPUT_staticMMO  "<staticMMOResource language=\"eng\" variant=\"default\" version=\"$version{$file_name}\" id=\"$file_name\.xml\"></staticMMOResource> \n";
			print INPUT_allstatic "XML__$viewid{$file_name}__eng__default__$version{$file_name}\n";
		}
	}
	else
	{
		print NEW_FILE_ADDED "$file_name\n";
		$num_of_new_files = $num_of_new_files+1;
	}
 	

}
close(INPUT_allstatic);
close(NEW_FILE_ADDED);
#close(INPUT_staticMMO);

    print("\n\n============================================================================================================");
	print("\n============================================================================================================");
	print("\n============================================================================================================\n\n\n");
	print "\t\t No. of files in the input CSV file \($input_file\) :  $num_of_input_files.\n";
	print "\t\t No. of files updated in the NEW_$config_file :  $num_of_files_updated.\n";
	print "\t\t No. of files newly added :  $num_of_new_files.\n";
	print("\n\n\n============================================================================================================");
	print("\n============================================================================================================");
	print("\n============================================================================================================\n\n\n");

if (-s "new_files_added.txt")
{
	print("\n\n==============================================================================================================================================\n\n\n");
	print "\t\t Please see 'new_files_added.txt' for the list of new files/folders.\n\t\t Please add them manually in the newly generated config file 'NEW_$config_file'.\n";
	print("\n\n==============================================================================================================================================\n\n\n");
}
}
#######################################################################################################
####################################### Modify AllStaticResources Tag ##################################
sub modify_AllStaticResources
{
open(READ_INPUT_AllStatic,"$temp_directory/input_allStaticResources.xml") || die("Can't open the file input_allStaticResources.xml");
open(READ_FORMATTED_AllStatic,"$temp_directory/formatted_allStaticResources.xml") || die("Can't open the file formatted_allStaticResources.xml");
open(NEW_AllStatic,">$temp_directory/new_allStaticResources.xml") || die("Can't create the file new_allStaticResources.xml") ;

@array_formatted = <READ_FORMATTED_AllStatic>;

while($read_READ_INPUT_AllStatic = <READ_INPUT_AllStatic>)
{
	@split_input_AllStatic = split('__',$read_READ_INPUT_AllStatic);
	$join_input_AllStatic = join('__',@split_input_AllStatic[0..3]);
		
	for ($i=0; $i<@array_formatted; $i++) 
	{
		if ($array_formatted[$i] =~ /$join_input_AllStatic/)
		{
				$array_formatted[$i] = $read_READ_INPUT_AllStatic;
				
		}
		else
		{
				#print("Old version\n"); #### could also be used to give warnings for new files which are not in uris
		}
	}	
	
}

print NEW_AllStatic @array_formatted;


close(NEW_AllStatic);
close(READ_FORMATTED_AllStatic);
close(READ_INPUT_AllStatic);
}

###############################################################################################################
############################# Modify StaticXMLResources/StaticMMOResources Tag#################################
sub modify_StaticResources
{
use XML::Twig;
my $twig= new XML::Twig;


   open(NEW_staticResources,">$temp_directory/new_staticResources.xml");
   open(INPUT,"$input_file");

		while ($read_INPUT = <INPUT>)
		{
			
			@file_and_version = split(',',$read_INPUT);
			$file_and_version[0] =~ s/\s+//;			## removing spaces in input file, if any
			$file = $file_and_version[0];
			@split_file = split('/',$file);
			$join_file = join('/',@split_file[-3..-1]);
			push @array_input_last_three,$join_file;
			$version{$join_file} = @file_and_version[1];		### creating the associative array of versions wrt file name
			$version{$join_file} =~ s/\n//;
			
		}

close(INPUT);


$twig->parsefile( "$temp_directory/old_staticMMOResource.xml"); 
my $root= $twig->root;  
my @ids= $root->children;

foreach my $resource (@ids)
{
   
   my $id_XML  = $resource->att('id');					## finding attribute ID i.e. file name
   my $variant = $resource->att('variant');
   #print "$variant\n";
   @split_id_XML = split('/',$id_XML);					
   @split_id_XML_extention = split('\.',@split_id_XML[-1]);		## removing the extention due to DOCATO path is absolute
   $last_XML_three = join('/',@split_id_XML[-3..-2],$split_id_XML_extention[0]); 
   $last_XML_three =~ s/\.\.\///;
   
   
   for($i=0; $i<@array_input_last_three; $i++)
   {
   	
		if ( $array_input_last_three[$i] =~ /$last_XML_three/ ) 
		{ 
			if ($variant ne "thumbnail") # we do not need to update the thumbnail of any image
			{
				$resource -> set_att('version', $version{$last_XML_three}); 
			}	
		}
   	
   }
   
}



$twig -> set_pretty_print('indented_a');
print {NEW_staticResources} $twig -> sprint;

close(NEW_staticResources);
}


#####################################################################################################################
############################################# Combine All The Files ##################################################
sub combine_all_files
{
	open(NEW_CONFIG,">NEW_$config_file") || die("Can't create NEW_$config_file.");
	open(OLD_CONFIG,"$config_file") || die("Can't open $config_file.");
	
	while($read_line_old_confg = <OLD_CONFIG>)
	{
		if ($read_line_old_confg !~ /<staticResources>/)
		{
			print NEW_CONFIG "$read_line_old_confg" ;
		}
		if ($read_line_old_confg =~ /<staticResources>/)
		{
			last;
		}
		
	}
	
	
	close(OLD_CONFIG);
	
	print NEW_CONFIG "<staticResources>\n";
	
	open(NEW_AllStatic,"$temp_directory/new_allStaticResources.xml");
	while(<NEW_AllStatic>)
	{
		s/\n/ /; # Remove new line character as it is casusing error while uploading it ti Docato
		print NEW_CONFIG "$_";
	}
	close(NEW_AllStatic);
	
	open(NEW_Static,"$temp_directory/new_staticResources.xml");
	while(<NEW_Static>)
	{
		print NEW_CONFIG "$_" unless (/<staticResources>/ || /<\/staticResources>/);
	}
	close(NEW_Static);
	
	print NEW_CONFIG "<\/staticResources>\n";
	
	open(URIS,"$temp_directory/uris.xml");
	while(<URIS>)
	{
		print NEW_CONFIG "$_";
	}
	close(URIS);
	
	print NEW_CONFIG "<\/configuration>\n";
	
	close(NEW_CONFIG);

}



