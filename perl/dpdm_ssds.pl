############ Author : Amitabh Kumar (B30792) / Niraj Gandhi (B49052) ###################
###############################################################

############### Intent of this script?############################################
# The dpdm_ssds.pl script parses the csv file exported from designPDM, which includes the errata details that are in PDM and not moved to XML and creates individual topics for each errata items. 
####################################################################################
############### How to use this script?############################################
# 1. Export the simple csv file from design PDM that will include all the errata items for which topics needs to be created
# 2. Install XML::Twig package
# 3. Open Command prompt.
# 4. perl dpdm_ssds.pl <file_name>
# 5. See output directory : "topics" for the individual errata topics. If you already have the topics folder in place, be ensure to remove the existing files to prevent mess up. 
# 6. Do the manual editing as required in the output files:
#	 a. Edit the errata details as per the requirement.
#	 b. Add the impact details as required. For this purpose, a placeholder for simple table is added in the file. If not required, remove this table.
# 	 c. Under tracking, add the dPDM ticket corresponding to the errata number.
#    d. The script does not include the 'Software status' details in the output topic. This will be taken care once the errata dtd will be updated.
####################################################################################


#!/run/pkg/TWW-perl-/5.12.2/bin/perl

# Including custom libraries
# BEGIN { push @INC, '/home/b30792/LIBRARIES/' }

# Includes
use Exporter ();
use Term::ANSIColor;
use strict;
use warnings;

#use SimpleCSV qw(:ALL);
use Getopt::Long;
use Data::Dumper;
use XML::Twig;

our($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $DEBUG, $Verbosity);

 $VERSION = "1.00";
 @ISA = qw(Exporter);
 @EXPORT = qw();
 @EXPORT_OK = qw( $DEBUG &parseCSV &getRow);
 %EXPORT_TAGS = ( 'ALL'     => \@EXPORT_OK );
 $DEBUG = 0;
 $Verbosity = 1;

my ($input_file_name) = $ARGV[0]; # pass the input excel sheet

removeline("\"Errata\"", $input_file_name); # called the subroutine 'removeline' to remove the first row containing the word "Errata"

mkdir my $output_directory = "topics"; # create the output directory "topics" at the same level the script is available
my %myCSV = parseCSV($input_file_name,1); # parse the excel sheet
my %row = ("check",1); # checks the first row of the updated excel sheet
my $incr=1; # variable to assign the row number that will be processed, assigning 1 to start with the first row
my $numRows = scalar @{$myCSV{'QCR Number'}}; # count the number of rows using the 'QCR Number'
while (keys %row) # start the loop until there is data in the row
{
if ($incr <= $numRows) # loop until the row number is less than/equal to the row count
{
my %row = getRow(\%myCSV,$incr); # extract the row data and assign to the array
my @errNum = split((/^(\D+)(\d+)$/),$row{'QCR Number'}); # split the errata number ERR  separated from the numeric value
$errNum[1]="A-"; # replaced 'ERR' with 'A-'
foreach my $row (keys(%row)) # start the loop to read each row
{
my $err_file_name = ($errNum[1].$errNum[2].".xml"); # generates the file name
open(ERRATA,">$output_directory/$err_file_name"); # open the output file for editing and printing the XML details
print ERRATA "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
 <!DOCTYPE errata  PUBLIC \"-//FSL//DTD Errata//EN\" \"../../../../../../catalog/FSL--DTD-Errata--EN.dtd\">

<errata id =\"$errNum[1]$errNum[2]\">
 <errata-title>
    <errata-id>$errNum[1]$errNum[2]</errata-id>
    <headline>$row{'Title'}</headline>
  </errata-title>
  <affects>
    <affected-component></affected-component>
  <impact>
      $row{'Errata Details (Page 3).Impact'}
      <simpletable>
        <strow>
          <stentry></stentry>
          <stentry></stentry>
           <stentry></stentry>
        </strow>
      </simpletable>
    </impact>
  </affects>
  <tracking>
    <origin-system>DesignPDM</origin-system>
    <origin-uid>$row{'QCR Number'} / dPDM ticket # </origin-uid>
    <origin-date/>
  </tracking>
  <erratabody>
    <erratadesc>
      <p>$row{'Errata Details (Page 3).Errata Description'}</p>
    </erratadesc>
    <workaround>
      <p>$row{'Errata Details (Page 3).Errata Workaround'}</p>
    </workaround>
    <fix-plan>
      <p>$row{'Errata Details (Page 3).Projected Solution'}</p>
    </fix-plan>
  </erratabody>
</errata>";
close(ERRATA);
}
$incr++; # increments the variable to move to the next row
}
else
{
last; # close the loop if there is no data in the row
}
}
# removes the row of the excel sheet depending on the input value passed to the subroutine
sub removeline
{
my $name = shift;
my $fileName = shift;

# Read file into an array for processing
open(my $read_fh, '<', $fileName) or die qq(Can't open file "$fileName" for reading: $!\n);
my @file_lines = <$read_fh>;
close($read_fh);

# Rewrite file with the line removed
open(my $write_fh, ">", $fileName) or die qq(Can't open file "$fileName" for writing: $!\n);
foreach my $line (@file_lines)
{
print {$write_fh} $line unless($line =~ /^$name/);
}
close( $write_fh );
}

sub INFO{
   my $s = shift;
   my $v = shift;
   if(not defined $v){
      $v = 1;
   }
   if($v <= $Verbosity){
      print "INFO : $s\n";
   }
}

sub ERROR{
   my $msg = shift;
   print color 'red';
   print "\nERROR : $msg\n";
   print color 'reset';
   exit(1);
}

sub WARNING{
   my $msg = shift;
   print color 'cyan';
   print "WARNING : $msg\n";
   print color 'reset';
}

sub DEBUG{
   my $s = shift;
   my $id = shift;
   if(not defined $id){
      $id = 'DEBUG_MESSAGE_CODE';
   }
   if($Verbosity == 4){
      print "DEBUG[$id] : $s\n";
   }
}

sub trim{
   my $s = shift;
   $s =~ s/^\s+|\s+$//g;
   DEBUG("Inside trim function. Trimmed \'$s\'", 'LIB-Utilities:trim');
   return $s;
}

sub isint{
   my $val = shift;
   if(defined $val){
      return ($val =~ m/^\d+$/);
   }
   else{
      return 0;
   }
}

sub parseCSV{
   my $name;
   my $headerRow;
   if((scalar @_) == 1 ){
      $name = shift;
      $headerRow = -1;
      DEBUG("NAME=$name\t HEADER_ROW=$headerRow", 'LIB-SimpleCSV:parseCSV');
   }
   elsif((scalar @_) == 2 ){
      $name = shift;
      $headerRow = shift;
      DEBUG("NAME=$name\t HEADER_ROW=$headerRow", 'LIB-SimpleCSV:parseCSV');
      ERROR("Header row number in parseCSV has to be an integer!") if(!isint($headerRow));
   }
   else{
      ERROR("Invalid number of arguments in function 'parseCSV'!");
   }

   open(INFILE, "<$name") or ERROR("Cannot locate file '$name' in function 'parseCSV'!");
   my %CSV;
   my $debugline;
   my $rowNo = 1;
   my $line;
   my @headerName;
   my $colLength = 0;
   while(<INFILE>){
      $line = $_;
      $debugline = $line;
      chomp($debugline);
      DEBUG("CurrentLINE=$debugline", 'LIB-SimpleCSV:parseCSV');
      my $number = () = $line =~ /\"/gi;
      while($number % 2){
         my $nextln = <INFILE>;
         $debugline = $nextln;
         chomp($debugline);
         DEBUG("NextLINE=$debugline", 'LIB-SimpleCSV:parseCSV');
         chomp($line);
         $line = $line." ".$nextln;
         $debugline = $line;
         chomp($debugline);
         DEBUG("Current LINE status=$debugline", 'LIB-SimpleCSV:parseCSV');
         $number = () = $line =~ /\"/gi;
      }
      if($rowNo == $headerRow or $headerRow == -1){
         my $oneByte;
         my $data = '';
         my $dataDone = 0;
         my $quotedData = 0;
         my @linebreak;
         $debugline = $line;
         chomp($debugline);
         DEBUG("Inside header row. CurrentRow=$rowNo\tDATA=\[$debugline\]", 'LIB-SimpleCSV:parseCSV');
         
         @linebreak = split(//, $line);
         for(my $i = 0; $i < (scalar @linebreak); $i++){
            $oneByte = $linebreak[$i];
            if($oneByte eq '"' and $quotedData == 0){
                     $quotedData = 1;
                     DEBUG("CHAR=$oneByte Quoted=$quotedData", 'LIB-SimpleCSV:parseCSV');
            }
            elsif($oneByte eq '"' and $quotedData == 1){
               my $nextByte;
               $nextByte = $linebreak[++$i];
               DEBUG("CHAR=$oneByte NextChar=$nextByte Quoted=$quotedData", 'LIB-SimpleCSV:parseCSV');
               if($nextByte eq '"'){
                  $data = $data.'""';
               }
               elsif($nextByte eq ',' or $nextByte eq "\n"){
                  $quotedData = 0;
                  $dataDone = 1;
               }
               else{
                  $data = $data.$nextByte;
                  $quotedData = 0;
               }
            }
            elsif($quotedData == 0 and $oneByte eq "\n"){
               $dataDone = 1;
            }
            elsif($quotedData == 0 and $oneByte eq ','){
               $dataDone = 1;
            }
            else{
               $data = $data.$oneByte;
            }
            
            if($dataDone){
               push @headerName, $data;
               $CSV{$data} = [];
               $dataDone = 0;
               $quotedData = 0;
               $data = '';
            }
         }
         if($rowNo == $headerRow){
            last;
         }
         if($headerRow == -1 and $colLength < (scalar @headerName)){
            $colLength = (scalar @headerName);
            DEBUG("Length=$colLength Row=\[@headerName\]", 'LIB-SimpleCSV:parseCSV');
         }
         undef @headerName;
      }
   }
   if($headerRow == -1){
      @headerName = 1..$colLength;
      DEBUG("Mock_Header=\[@headerName\]", 'LIB-SimpleCSV:parseCSV');
   }
   DEBUG("Header Row=\[@headerName\]", 'LIB-SimpleCSV:parseCSV');
   close(INFILE);

   open(INFILE, "<$name") or ERROR("Cannot locate file '$name' in function 'parseCSV'!");
   binmode(INFILE);

   # seek INFILE, 0, 0;
   my $col = 0;
   my $row = 1;
   my $oneByte;
   my $data = '';
   my $dataDone = 0;
   my $quotedData = 0;
   while(read(INFILE, $oneByte, 1)){
      # print($oneByte." ");
      # $i++;
      # print("\n") if((ord $oneByte) == 10);
      if($oneByte eq '"' and $quotedData == 0){
         $quotedData = 1;
      }
      elsif($oneByte eq '"' and $quotedData == 1){
         my $nextByte;
         read(INFILE, $nextByte, 1);
         if($nextByte eq '"'){
            $data = $data.'""';
         }
         elsif($nextByte eq ',' or (ord $nextByte) == 10){
            $quotedData = 0;
            $dataDone = 1;
         }
         else{
            $data = $data.$nextByte;
            $quotedData = 0;
         }
      }
      elsif($quotedData == 0 and (ord $oneByte) == 10){
         $dataDone = 1;
      }
      elsif($quotedData == 0 and $oneByte eq ','){
         $dataDone = 1;
      }
      else{
         $data = $data.$oneByte;
      }

      if($dataDone){
         DEBUG("BEFORE-- ROW=$row COL=$col", 'LIB-SimpleCSV:parseCSV');
         if($row != $headerRow){
            push @{$CSV{$headerName[$col]}}, $data;
         }
         DEBUG("HeaderName=$headerName[$col] DATA=$data DataSoFar=\[@{$CSV{$headerName[$col]}}\]", 'LIB-SimpleCSV:parseCSV');
         $row = $row + int(($col + 1) / (scalar @headerName));
         $col = ($col + 1) % (scalar @headerName);
         DEBUG("AFTER-- ROW=$row COL=$col", 'LIB-SimpleCSV:parseCSV');
         $dataDone = 0;
         $quotedData = 0;
         $data = '';
      }
   }
   close(INFILE);
   # print Dumper(%CSV);
   return(%CSV);
}

sub getRow{
   my $name;
   my $row;
   my %CSV;
   if((scalar @_) == 2 ){
      $name = shift;
      %CSV = %$name;
      $row = shift;
      DEBUG("CSV_NAME=$name ROW=$row", 'LIB-SimpleCSV:getRow');
      ERROR("Header row number in parseCSV has to be an integer!") if(!isint($row));
   }
   else{
      ERROR("Invalid number of arguments in function 'getRow'!");
   }
   
   my %data;
   foreach my $key (keys %CSV){
      if(defined $CSV{$key}[$row-2]){
         $data{$key} = $CSV{$key}[$row-1];
      }
      else{
         WARNING("All data not available for row $row accessed in SimpleCSV::getRow()");
      }
   }

  return(%data);
}

sub dumpCSV{
   my $name;
   my $hashname;
   my $headername;
   my %CSV;
   my @headers;
   if((scalar @_) == 3 ){
      $name = shift;
      $hashname = shift;
      %CSV = %$hashname;
      $headername = shift;
      @headers = @$headername;
      DEBUG("O/P_NAME=$name HASH_NAME=$hashname Header_NAME=$headername", 'LIB-SimpleCSV:parseCSV');
   }
   else{
      ERROR("Invalid number of arguments in function 'parseCSV'!");
   }
}
