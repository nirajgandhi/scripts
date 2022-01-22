use Exporter ();
use Term::ANSIColor;
use strict;
use warnings;
use File::Copy qw(move);
#use SimpleCSV qw(:ALL);
use Getopt::Long;
use Data::Dumper;
use XML::Twig;
#use Spreadsheet::ParseExcel;
#use Spreadsheet::ParseXLSX;
use Spreadsheet::Read;


my ($input_file_name) = $ARGV[0]; #pass the input file name

my $book = ReadData($input_file_name);
my $sheet= $book ->[4];
my $col_SoC;
#my $sheet_num=4;
mkdir my $output_directory = "topics";

print "Enter the SoC Name: <the name should match the column header for the device>\n";
my $socName= <STDIN>;
for my $row ($sheet->{minrow}+1)
       {  
            for my $col ($sheet->{mincol} ..  $sheet->{maxcol}) 
            {
            my $socTemp = $sheet->{'cell'}[$col][$row];
            #print "$socTemp\n";
            #chop($socTemp);
            chomp ($socName);
            #print "$socTemp\n";
            #print "$socName\n";
                        
            if ("$socTemp" eq "$socName")
            {
            $col_SoC=$col;            
            last;                      
            }
            }
        }


my $ccsr_file_name = ("temp_memory_map.dita"); # generates the file name
open(CCSR,">$output_directory/$ccsr_file_name"); # open the output file for editing and printing the XML details



print CCSR "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <!DOCTYPE topic PUBLIC \"-//FSL//DTD DITA Hardware IP Topic//EN\" \"dtd/ip-topic.dtd\">
<topic id=\"aa2111567_$socName\" xmlns:ditaarch=\"http://dita.oasis-open.org/architecture/2005/\">
  <title>System memory map</title>
  <body>
    <table id=\"aa110099_$socName\">
      <title>System memory map</title>
      <tgroup cols=\"5\">
        <colspec colname=\"col4\" colnum=\"1\" colwidth=\"1*\"/>
        <colspec colname=\"col5\" colnum=\"2\" colwidth=\"1*\"/>
        <colspec colname=\"col6\" colnum=\"3\" colwidth=\"1*\"/>
        <colspec colname=\"col7\" colnum=\"4\" colwidth=\"1*\"/>
        <colspec colname=\"col8\" colnum=\"5\" colwidth=\"1*\"/>
        <thead>
          <row>
            <entry>Start address</entry>
            <entry>End address</entry>
            <entry>Size</entry>
            <entry>Allocation</entry>
            <entry>Comment</entry>
          </row>
        </thead>
        <tbody>\n";
    #for my $sheet ($book ->[$sheet_num]) 
    #{
      
        foreach my $row ($sheet->{minrow}+1 .. $sheet->{maxrow}) 
       {        
        if($row >= 1)        
        {
            print CCSR "<row>"; 
            my $col=$sheet->{mincol};                       
            foreach $col ($sheet->{mincol} ..  $sheet->{maxcol}) 
            {
            my @set = (4, 5, 7, 8, 15);
            my $count =1;
            my $cell = $sheet->{'cell'}[$col][$row];            
            my $soc = $sheet->{'cell'}[$col_SoC][$row];
            
            if ("$soc" eq ("Yes"))
            {
            while ($count <= "5")
            {
                if ($col == $set[$count-1])
                    {
                    #if ($cell) 
                     #   {
                        print CCSR "
                          <entry>$cell</entry>\n";
                      #  }
                    }   
                    $count++;         
            }
            }
            else
            {
            if ("$soc" eq ("No"))
            {
            while ($count < "5")
            {
                if ($col == $set[$count-1])
                    {
                    #if ($cell) 
                     #   {
                        print CCSR "
                          <entry>$cell</entry>\n";
                      #  }
                    }
            $count++;                
            }
            while ($count == "5")
            {
                if ($col == $set[$count-1])
                    {
                    #if ($cell) 
                     #   {
                        print CCSR "
                          <entry>Reserved</entry>\n";
                      #  }
                    }
            $count++;                
            }
            }
            }
            
            }
            print CCSR "</row>\n";
            }
        }
        
        #$sheet_num++;
        #print $sheet_num;
    #}

       print CCSR"     </tbody>
      </tgroup>
    </table>
  </body>
</topic>";
close (CCSR);

removeEmptyRows();


sub removeEmptyRows
{
my $emptyRow= '<row></row>';
open(CCSR,"<$output_directory/$ccsr_file_name");
open (my $outfile, ">", "$output_directory/system_memory_map.dita") or die $!;
while (<CCSR>)
{
$_=~s/$emptyRow//g;
print $outfile $_;
}
move "$output_directory/$ccsr_file_name", $outfile;
close (CCSR);
close ($outfile);
}

