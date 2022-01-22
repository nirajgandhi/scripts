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
my $sheet= $book ->[2];
my $col_SoC;
my $col;
mkdir my $output_directory = "test_topics";

print "Enter the SoC Name: <the name should match the column header for the device>\n";
my $socName= <STDIN>;
for my $row (11)
       {  
            for my $col ($sheet->{mincol} ..  $sheet->{maxcol}) 
            {
            my $socTemp = $sheet->{'cell'}[$col][$row];
            #print "$socTemp\n";
            chomp ($socName);
            #print "$socTemp\n";
            #print "$socName\n";perl 
                        
            if ("$socTemp" eq "$socName")
            {
            $col_SoC=$col; 
            #print $col_SoC;           
            last;                      
            }
            }
        }


my $intr_file_name = ("temp_interrupt_assignment.dita"); # generates the file name
open(INTR,">$output_directory/$intr_file_name"); # open the output file for editing and printing the XML details



print INTR "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <!DOCTYPE topic PUBLIC \"-//FSL//DTD DITA Hardware IP Topic//EN\" \"dtd/ip-topic.dtd\">
<topic id=\"aa2222567_$socName\" xmlns:ditaarch=\"http://dita.oasis-open.org/architecture/2005/\">
  <title>Internal interrupt sources</title>
  <body>
    <table id=\"aa220088_$socName\">
      <title>Interrupt assignment</title>
      <tgroup cols=\"3\">
        <colspec colname=\"col1\" colnum=\"1\" colwidth=\"1*\"/>
        <colspec colname=\"col2\" colnum=\"2\" colwidth=\"1*\"/>
        <colspec colname=\"col3\" colnum=\"3\" colwidth=\"1*\"/>
        <thead>
          <row>
            <entry>Interrupt identifier</entry>
            <entry>ARM interrupt source</entry>
            <entry>Notes</entry>
          </row>
        </thead>
        <tbody>\n";
    #for my $sheet ($book ->[$sheet_num]) 
    #{
      
        foreach my $row (12 .. 305) 
       {        
        if($row >= 1)        
        {
            print INTR "<row>"; 
            #my $col=$sheet->{mincol};                       
            foreach $col ($sheet->{mincol} ..  $sheet->{maxcol}) 
            {
            my @set = (2, 3, 7);
            my $count =1;
            my $cell = $sheet->{'cell'}[$col][$row];            
            my $soc = $sheet->{'cell'}[$col_SoC][$row];
            print "$soc\n";
            
            if ("$soc" eq ("Yes"))
            {
            while ($count <= "3")
            {
            #print "$col\n";
                if ($col == $set[$count-1])
                {
                    #if ($cell) 
                    #   {
                    print INTR "
                    <entry>$cell</entry>\n";
                    #   }
                }   
                $count++;         
            }
            }
            
            
            
            else
            {
            
            if ("$soc" eq (""))
            {
            while ($count < "3")
            {
            #print "$col\n";
                if ($col == $set[$count-1])
                {
                    if ($sheet->{'cell'}[3][$row] eq "" && $sheet->{'cell'}[7][$row] eq "")
                    {
                    print INTR "
                    <entry namest=\"col1\" nameend=\"col3\"><b>$sheet->{'cell'}[2][$row]</b></entry>\n";
                    }
                    else
                    {
                    print INTR "
                    <entry>$cell</entry>\n";
                    }
                }   
                $count++;         
            }
            
            
            while ($count == "3")
            {
            #print "$col\n";
                if ($col == $set[$count-1])
                {                    
                    print INTR "
                    <entry>Reserved</entry>\n";
                    #}
                }   
                $count++;         
            }
            
            
            }
            
            }
            
            
            
                       
            
            }
            print INTR "</row>\n";
            }
            }
            
            #}
        #}
        
        #$sheet_num++;
        #print $sheet_num;
    #}

       print INTR"     </tbody>
      </tgroup>
    </table>
  </body>
</topic>";
close (INTR);

removeEmptyRows();


sub removeEmptyRows
{
my $emptyRow= '<row></row>';
open(INTR,"<$output_directory/$intr_file_name");
open (my $outfile, ">", "$output_directory/interrupt_assignments.dita") or die $!;
while (<INTR>)
{
$_=~s/$emptyRow//g;
print $outfile $_;
}
move "$output_directory/$intr_file_name", $outfile;
close (INTR);
close ($outfile);
}
