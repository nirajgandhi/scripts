# This scripts automates following editorial activities:

# • Ensure headings, figure caption, and table headings are in sentence case. 
# • Ensure capitalization is used appropriately (only register/field names,).
# • Replace instances of GBytes with GB, Mbytes with MB and Kbytes with KB.
# • Check instances, such as 1/4/8 bit to 1-, 4-, and 8 bit.

# Run this script on 'topics' folder.

#use File::Path

#Path of the topics folder containing xml files to be specified here.
@files = <topics/*>; # list of all files 

$directory = "output"; # create output directory for modified files.
system ("if not exist \"\output\\topics\" mkdir \output\\topics"); # Create output\topics directory

my $line_num = 0; # file line number
# my @title_matches;

# Parse each file in the topics folder
foreach $file (@files) 
{
	$change_flag = 0;
	open(FILE_OLD, "$file") or die("Can't open $file to read. \n");
	@old_file = <FILE_OLD>; # Read whole file
	close (FILE_OLD);
	open(FILE_NEW,">$directory/$file") or die("Can't create $file in $directory directory. \n"); # create new file in output directory.
	#$line_num = 0;
	for ($old_file_line = 0; $old_file_line < @old_file; $old_file_line++) 
    {
        #$line_num++;
		
		####### Replace instances of GBytes with GB, Mbytes with MB and Kbytes with KB.
		
		if($old_file[$old_file_line] =~ s/G[bB]ytes*/GB/g)
		{
			#$log_assoc{$file}{$old_file_line+1}{$old_file[$old_file_line]} = $new_file; # Associative array to generate log file.
		}
		
		if($old_file[$old_file_line] =~ s/M[bB]ytes*/MB/g)
		{
		
		}
		if($old_file[$old_file_line] =~ s/K[bB]ytes*/KB/g)
		{
		
		}
		##############################################################
		
		####################### Ensure headings, figure caption, and table headings are in sentence case.  ##################
		if ($old_file[$old_file_line] =~ /(?<=<title>)(.*?)(?=<\/title>)/g)  # Extracts text between <title> </title>
        {
            $title = $1;
            # push @title_matches, $1;
			#@split_title = split(/[\t ]+/ ,$title); # @split_title = split(/ +/ ,$title); # split sentence in words.
			@split_title = split(' ',$title); # ignore leading/trailing whitespaces
			###########
			#e.g. Change <title> RSP Entry</title> into <title>RSP Entry</title>
			###########
						
			for ($word = 0; $word < @split_title; $word++) #foreach my $s_w (@split_title) # For each word in the sentence
			{
				if ($split_title[$word] =~ /([A-Z][-_a-zA-Z0-9]*[\s]{0,1}){2,}/) 
				#The regex searches for two or more consecutive occurrences of the following sequence: a capital letter followed by any amount of lowercase/uppercase/numerical/hyphen characters (alter this to any range of non-whitespace characters to suit your needs of course), followed by a whitespace character.
				#(/\b([A-Z][a-z]*){2,}\b/) #/(?!^.*[A-Z]{2,}.*$)^[A-Za-z]*$/
				{
					# If two consecutive letters are capitals, do nothing. 
					# This is to check words like register name, acronym, etc.
					
					#print("$s_w \n");
					#print("$split_title[$word] \n");
				}
				elsif ($split_title[$word] =~ /\//) # If there is any forward slash in the word, do nothing.
				{
					# do nothing
					# e.g. L2/L3, I/O
				}
				else
				{
					if ($word == 0)
					{
						if ($split_title[0] ne (ucfirst lc $split_title[0])) # if first letter of first word is not capital
						{
							# Sentence case for first word in the sentence. 
							# lc = lower case # ucfirst = upper case first letter of word 
							
							# $temp_first = ucfirst lc $split_title[0]; 
							# $split_title[0] = $temp_first;
							$change_flag = 1;
							$split_title[0] = ucfirst lc $split_title[0]; 
						}
					}
					else
					{
						# Lower case for all others.
						
						# $temp_other = lc $split_title[$word];
						# $split_title[$word] = $temp_other;
						if ($split_title[$word] ne (lc $split_title[$word])) # if word is not in lower case
						{
							$change_flag = 1;
							$split_title[$word] = lc $split_title[$word];
						}
					}
				}
			}
			#print("@split_title \n");
			
			$new_file = "<title>".join (" ", @split_title)."</title>";
			print FILE_NEW "$new_file\n"; # Write new file.
			
			if ($change_flag == 1)
			{
				$log_assoc{$file}{$old_file_line+1}{$old_file[$old_file_line]} = $new_file; # Associative array to generate log file.
			}
			
        }
		else
		{
			# Write new file as it is old file if no <title>.
			print FILE_NEW "$old_file[$old_file_line]";
		}
		############################################################################################################
    }
	
	close(FILE_NEW);
	
}

################################### Generate log file. ##########################################################
open (ED_CHK, ">editorial_checks.log");
print ED_CHK "Followings are modifications in: \n\n";
foreach $f_name (keys %log_assoc)
{
	print ED_CHK "\n\n---------------------------------- $f_name ---------------------------------- \n";
	foreach $l_num (keys %{$log_assoc{$f_name}})
	{
		foreach $old_f_line (keys %{$log_assoc{$f_name}{$l_num}})
		{
			print ED_CHK "line: $l_num    $old_f_line is changed to $log_assoc{$f_name}{$l_num}{$old_f_line} \n";
		}
	}	
}

close (ED_CHK);
##################################################################################################################














######### IGNORE following section.############################

########### Sentence case #############
# $temp_text = "hI, ThEre!";
# $temp_mod_text = ucfirst lc $temp_text; # lc = lower case , ucfirst = upper case first letter
# print("$temp_mod_text \n");
# if $temp_text != $temp_mod_text, changes done, generate log
#######################################

########### Extract text between tags ################
# my $str
   # = "<ul>"
   # . "<li>hello</li>"
   # . "<li>there</li>"
   # . "<li>everyone</li>"
   # . "</ul>"
   # ;

# my @matches;
# while ($str =~/(?<=<li>)(.*?)(?=<\/li>)/g) 
# {
  # push @matches, $1;
# }

# foreach my $m (@matches) 
# {
   # print $m, "\n";
# }
###################################################

############################## Associative array ################
#$result_assoc{$array[0]} = $array[2];
			# print ("Associative Results : \n");
# 
# foreach $rslt (keys(%result_assoc)) 
# {
# 	print ("$rslt: $result_assoc{$rslt}\n");
# }
#foreach $bom ( keys %HoH ) 
# {
# 	print "\n $bom: \n { ";
# 	for $mo_name ( keys %{ $HoH{$bom} } ) 
# 	{
# 		for $t_name ( keys %{ $HoH{$bom}{$mo_name} } ) 
# 		{
# 			print "\n $t_name=$HoH{$bom}{$mo_name}{$t_name} ";
# 		}
# 	}
# 	print "}\n";
# }
################################################################
#######################leading/trailing whitespaces################################################
# my $string = "   a b c  "; # note leading/trailing whitespaces

# my @array1 = split /\s+/, $string; # returns '', 'a', 'b', 'c' (4 item +s)
# my @array2 = split ' ',   $string; # returns     'a', 'b', 'c' (3 item +s)
# foreach $ar(@array2)
# {
	# print ("$ar \n ");
# }
# print ("@array2 \n ");
#####################################################################