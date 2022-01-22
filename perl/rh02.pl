#
# new version rh02:
#   uses single-file download (output from xquery)
#     structure of downloaded file:
#         single topic with a section element for each book chapter
#         section elements have @outputclass with values of:
#             "simple": represents a simple topicref (one table)
#             "nested": represents multiple topicrefs nested in a topichead (two or more tables)
#         each table can have these attributes:
#             @outputclass: has the topic name from docato (e.g., revision_history_reset_p4080)
#             @rev: "out" (but only present if topic is checked out)
#
#     differences:
#       all xrefs contain absolute path on Docato
#       

use 5.010;
use XML::LibXML;
use Date::Manip;
use Encode;
use Log::Log4perl qw(get_logger :levels);

# ***********
# *********** declarations, global first
# ***********

$scriptVersion = "2013/04/04";

$DATE_START_P = undef;          # parsed start date
$DATE_END_P   = undef;          # parsed end date
$lastRev      = 'x';            # default values for rev nos
$thisRev      = 'y';

$usingSimpleTable = 0;          # flag when using simpletable elements
$preservedCols = "0010010";          # standard columns that are preserved

################################ Modified by Niraj Gandhi - b49052 ######################
# $internalCols  = "1111110"; # columns that are preserved for internal versions
$internalCols  = "0010110";          # Generates three columns for internal versions
#########################################################################################

$internalFlag = 0;              # assume not internal version

$outputFH;                      # reusable output file handle
$logFileName;                   # log file name

$noChangesMessage = 'No substantive changes';       # message to print if filtered table empty

# *********** 'constants'
my $outputMapName = 'revision_history_map';
my @allFSLselectAtts = qw(
    product
    audience
    platform
    otherprops
    feature
);
#    platform           # platform and props shouldn't be used in our world
#    props

my $outputDir = "out";      # where the map & topics go
my $mapFile;                # name only of the map that links to all the rev histories

my @mapList   = ();         # empty list for output topic names (to make output map)
my @mapsFound   = ();       # empty list for results of map search

# ***********
# *********** beginning of main
# ***********

say STDERR "\nnew revision history generation script (rev 2) version: $scriptVersion";
$parser = XML::LibXML->new;     # global variable
checkArgs();                    # make sure we have start/end dates
my $run = setupOutput();        # create output directory & return 3-digit random number string
init_logging( );

findSourceDoc( );               # search in . for one or more map files

if ( @mapsFound > 1 ) {
  print "\n*** Found ", scalar @mapsFound, " source documents. Get rid of all but one.\n";
  die "They are: @mapsFound\n";
}
elsif ( @mapsFound == 0 ) {
  die "No source documents found in current directory."
}

my $docSource = openFile( ".", $mapsFound[0] );    ## temporary name
my $mapTree = $parser->parse_string( $docSource );

print STDERR  "\nUsing dates: ";
print STDERR substr( $DATE_START_P, 0, 4) . '-' . substr( $DATE_START_P, 4, 2) . '-' . substr( $DATE_START_P, 6, 2);
print STDERR  "  through  ";
say   STDERR substr( $DATE_END_P, 0, 4) . '-' . substr( $DATE_END_P, 4, 2) . '-' . substr( $DATE_END_P, 6, 2) . "\n";

#
# plan for new version
#   issue reports:
#       tables with rev="out" (indicates checked-out topic)
#       section[ @outputclass='simple' ] but more than one table
#       section[ @outputclass='nested' ] but more than two tables
#   walk through section elements
#       generate a topic for each
#         merge tables if @outputclass="nested"
#   

issueReports( $mapTree );
writeAllTopics( $mapTree );
writeMap2();

# ***********
# *********** end of main
# ***********

sub issueReports {
  my $sourceTree = shift;
  my $section;
  my @titles;
  say STDERR "Checking for checked-out source topics";
  my $logger = Log::Log4perl->get_logger("logger");
  $logger->debug( "$run:   Checking for checked-out source topics\n" );
  my @tables = $sourceTree->findnodes( "//table" );
   for $table ( @tables ) {
    my $rev = $table->getAttribute( 'rev' );
	#print "$rev\n";
    if ( $rev ) {
	################################################# Modified by Gandhi Niraj-b49052#####################################################
      # @titles = $table->findnodes( "title" ); # This reads the table title (<table><title></title></table>). 
												# There are many cases for which table title is not provided in the revision history file.
												# As suggested by Cihak Thomas, we can use @titles = $table->findnodes( 'preceding-sibling::*' );
												
	  #@titles = $table->getAttribute( 'outputclass' ); # So instead of using title node, it is efficient to use 'outputclass' (which is file name of the revision history) which will be always there in the XQuery result.
	  @titles = $table->findnodes( 'preceding-sibling::*' );
	  my $title = $titles[0]->textContent;
	  #my $title = $titles[0];
	#######################################################################################################################################
      say STDERR "  ****** topic is checked out: $title ******";
      $logger->warn( "$run:     ****** topic is checked out: $title ******\n" );
    }
  }
  say STDERR "\nChecking for source topics with too many tables";
  my @sections = $sourceTree->findnodes( "//section" );
  for $section ( @sections ) {
    my $oClass = $section->getAttribute( 'outputclass' );
    my $right = ( $oClass eq 'nested' ) ? 2 : 1;
    @tables = $section->findnodes( "table" );
    @tables = $section->findnodes( "simpletable" ) if @tables == 0;
    say STDERR "  ***too many tables" if $oClass > $right;
  }
  say STDERR "\n";
  my @mmos = $sourceTree->findnodes( "//xref[attribute::href = 'MMO_RESOURCE_TYPE']" );
  if ( @mmos > 0 ) {
    say STDERR "Found one or more references to MMOs:\n    search downloaded file for word 'MMO_RESOURCE_TYPE'";
    for my $mmo ( @mmos ) {
      @sections = $mmo->findnodes( "ancestor-or-self::section" );
      @titles = $sections[0]->findnodes( "title" );
      my $sTitle = $titles[0]->textContent;
      say STDERR "    Section: $sTitle";
    }
  }
}

sub writeAllTopics {
  my $sourceTree = shift;
  writeIntroTopic();
  say STDERR "\nWriting output topics\n";
  my $logger = Log::Log4perl->get_logger("logger");
  $logger->debug( "$run:   Writing output topics\n" );

  my @sections = $sourceTree->findnodes( "//section" );
  SECTION:
  for $section ( @sections ) {
    $usingSimpleTable = 0;        # 
    my @titles = $section->findnodes( "title" );
    my $titleNode = $titles[0];
    my $titleString = $titleNode->textContent;
    my $type = $section->getAttribute( 'outputclass' ); # nested or simple
    @tables = $section->findnodes( "table" );
    if ( @tables == 0 ) {
      $usingSimpleTable = 1;
      @tables = $section->findnodes( "simpletable" );
   }
    my $table1 = shift @tables;
    my $topicName = $table1->getAttribute( 'outputclass' );
    my $topicPath = $outputDir . "/topics/" . $topicName . ".xml";
    if ( $type eq 'simple' ) {
    $logger->debug( "$run:   Simple: $titleString\n" );
    }
    elsif ( $type eq 'nested' ) {
#      say STDERR " Nested " . $titleNode->textContent;         # log: trace?
      $logger->debug( "$run:   Nested: $titleString\n" );

      # $appendPoint will be the place in table1 where all other table rows are added...
      #   for simpletables, it's just table1, 
      #     but for regular tables it's table1's tbody element
      my @appendTo = $table1->findnodes( "tgroup/tbody" ) unless $usingSimpleTable;
      my $appendPoint = $usingSimpleTable ? $table1 : $appendTo[0];
      
      for $table ( @tables ) {                                # first table shifted off as table1
        # merge in rows
        my @rows = $table->findnodes( "tgroup/tbody/row" );
        for $row ( @rows ) {
          $appendPoint->addChild( $row );
        }
      }
    }
    else {
      say STDERR "Bad section type encountered";
      next SECTION;
    }
    tableClean( $table1 );            # remove all select atts and table title

    my $mapref = XML::LibXML::Element->new( "topicref" );
    $mapref->setAttribute( "href", 'topics/' . $topicName . '.xml' );
    copySAtts( $section, $mapref );
    push @mapList, $mapref;                   # pushing a fully formed topicref with select atts

    my $tableWhole = $table1->cloneNode( 1 );   # deep copy == 1
    killRows( $topicName, $table1 );
    writeTopic( $topicPath, $tableWhole, $table1, $titleNode->toString( 1 ) );
  }
  say STDERR "\n";
}

sub copySAtts {
  my $source = shift;
  my $target = shift;
  my @allAtts = $source->findnodes( '@*' );
  for $sAtt ( @allFSLselectAtts ) {
    my $value = $source->getAttribute( $sAtt );
    $target->setAttribute( $sAtt, $value ) if $value;
  }
}

sub writeMap2 {
    my $idNum = int( rand( 10000000)) + 10001;
    my $DOC = "MPC8999";                                    # delete this variable; use rand for id
    my ( $DAY, $MONTH, $YEAR ) = (localtime)[3,4,5];
    $YEAR += 1900;
    my $mapShell1 = <<ENDMAPSHELL1;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE documentmap PUBLIC "-//FSL//DTD DITA Document Map//EN" "FSL--DTD-DITA-Document-Map--EN.dtd">
<documentmap doctype="Block Guide" id="id-${idNum}" rev="X, $MONTH/$YEAR">
  <doctitle>
    <maindoctitle>Substantive changes from revision $lastRev to revision $thisRev</maindoctitle>
    <subdoctitle/>
  </doctitle>
  <docmeta>
    <document-id>
      <document-partnum>RH-${idNum}</document-partnum>
    </document-id>
  </docmeta>
ENDMAPSHELL1

    my $mapShell2 = <<ENDMAPSHELL2;
</documentmap>
ENDMAPSHELL2

    my $logger = Log::Log4perl->get_logger("logger");
    $logger->debug( "$run:   Writing map entries:\n" );

    open( my $outputFH, ">", $outputDir . "/$outputMapName.xml" ) or die "Can't open map.xml\n";
    print $outputFH $mapShell1;
    print $outputFH "    <topicref href='topics/__intro.xml'>\n";

# replaced with code in writeAllTopics (search on mapList)
=cut
    for my $element (@mapList) {
      my $section = $element->cloneNode( 0 );
      $section
      my $output = "<topicref href='topics/" . $section . "'/>";
      print $outputFH "      ${output}\n";
    }
=cut
    for my $topicref (@mapList) {
      my $output = $topicref->toString( 0 );
      print $outputFH "      ${output}\n";
    }

    print $outputFH "    </topicref>\n";
    print $outputFH $mapShell2, "\n";
    close ( $outputFH );
}

sub bad_href {
    my $topicref = shift;
    my $href = $topicref->getAttribute( "href" );
    return 1 if $href eq 'MISSING_LINK_TARGET';
    ! $href;
}

sub writeIntroTopic {
    my $banner = "Substantive changes from revision $lastRev to revision $thisRev";
    my $sd = substr( $DATE_START_P, 0, 4 ) . '-' . substr( $DATE_START_P, 4, 2 ) . '-' . substr( $DATE_START_P, 6, 2 );
    my $ed = substr( $DATE_END_P, 0, 4 ) . '-' . substr( $DATE_END_P, 4, 2 ) . '-' . substr( $DATE_END_P, 6, 2 );
    my $topicShell1 = <<ENDTOPICSHELL1;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE topic PUBLIC "-//FSL//DTD DITA Topic//EN" "FSL--DTD-DITA-Topic--EN.dtd">
<topic id="RHintro-${idNum}">
  <title>$banner</title>
  <body>
    <p audience="internal">Changes from $sd to $ed</p>
    <p>$banner are as follows:</p>
  </body>
</topic>
ENDTOPICSHELL1
    my $output = $outputDir . "/topics/__intro.xml";
    open ( $outputFH, ">", $output ) or die "Can't open $output\n";
    print $outputFH $topicShell1;
    close ( $outputFH );
}

sub init_logging {
    my $config = "log.conf";
    print STDERR "Logger\n" if -e $config;
    Log::Log4perl->init($config) if -e $config;
    my $logger   = Log::Log4perl->get_logger("logger");
    $logFileName = "log${run}.txt";
    say STDERR "Log file: $logFileName\n";
    my $appender = Log::Log4perl::Appender->new(
        "Log::Log4perl::Appender::File",
        filename => $logFileName,
        mode     => "append",
    );
    $logger->add_appender($appender);
    $logger->level($DEBUG) unless -e $config;

    my $layout = Log::Log4perl::Layout::PatternLayout->new( "%d %p> %L %M - %m%n");
    $appender->layout($layout);
}

sub setupOutput {
    my $randPart = sprintf( "%-0.3u", int rand( 1000 ) );
    while( -d $outputDir . $randPart ) {
        $randPart = sprintf( "%-0.3u", int rand( 1000 ) );
    }
      $outputDir .= $randPart;
      die "Internal error: bad output format" if $outputDir =~ / /;
      print STDERR "\nOutput directory: $outputDir\t";
      mkdir $outputDir unless -d "./$outputDir";
      mkdir $outputDir . '/topics' unless -d "./${outputDir}/topics";
      $randPart;
}

sub checkArgs {
    my $dieMsg = "I need two dates. I understand yyyy/mm/dd or mm/dd/yyyy.";
    die "\n$dieMsg\n" unless defined( $ARGV[1]);
    my $s1 = $ARGV[0];
    my $s2 = $ARGV[1];
    $DATE_START_P = ParseDate( $s1 );
    $DATE_END_P =   ParseDate( $s2 );
    die "\n$dieMsg\n" unless $DATE_START_P =~ /\d{10}:\d\d:\d\d/ && $DATE_END_P =~ /\d{10}:\d\d:\d\d/;
    if ( Date_Cmp( $DATE_START_P, $DATE_END_P ) > 0 ) {
      ( $DATE_START_P, $DATE_END_P ) = ( $DATE_END_P, $DATE_START_P )
    }
    if ( defined( $ARGV[2] ) ) {
      print "\nCan't adjust third parameter (revision number): Using generic wording\n" unless checkRevArg( $ARGV[2] );
    }
    if ( defined( $ARGV[3] ) ) {
      $argVal = lc $ARGV[3];
      die "\nIllegal 4th argument: $argVal. Please enter 'x' or 'X'.\n" unless $argVal eq 'x';
      $preservedCols = $internalCols;
      $internalFlag = 1;              # set flag for internal version
      say STDERR "\n*****************************************************************";  
      say STDERR "*****************************************************************";  
      say STDERR "*****************************************************************";  
      say STDERR "************** Internal Version: Not for customers **************";  
      say STDERR "*****************************************************************";  
      say STDERR "*****************************************************************";  
      say STDERR "*****************************************************************";  
      }
}

sub checkRevArg {   # return 1 if revision can be understood and decremented
    my $current = uc shift;
    die "Unsupported version: $current" if split("", $current) != 1;
    my $last = $current - 1;
    if ( $current eq '0' || $current eq 'A' ) {     # may need special handling for rev 0
        return 0;
    }
    if ( $current =~ /\D/ ) {                                       # It's not numeric
        return 0 if $current !~ /^[A-Z]$/;            # bail if not alphabetic
        $last = chr( ord( $current ) - 1 );
    }
    elsif ( $current =~ /\W/ ) {                                    # It's numeric
        $last = $current - 1;               # already done
    }
    $thisRev = $current;
    $lastRev = $last;
    return 1;
}

sub tableClean {
    my $tableNode = shift;
    # remove all select atts from table node
    for my $selectAtt (@allFSLselectAtts) {
        $tableNode->removeAttribute( $selectAtt );
    }
    return if $usingSimpleTable;
    my @titles = $tableNode->findnodes( "title" );

    $titles[0]->unbindNode() if @titles > 0;         # skip it if no title present
}

sub makeAbsolutePath {
    my $absPath = shift;
    my @components = split( "/", $absPath );
    pop @components;                                # discard file name
    $absPath = join( "/", @components );
    $absPath =~ s/^eng//;
    $absPath;
}

sub taintRow {
    my $rowNode = shift;
    $rowNode->setAttribute( "otherprops", "fix_revhistory" );
}

sub killRows {
    my $fName = shift;
    my $tableNode = shift;
    my $rowExprXPATH   = "tgroup/tbody/row";
    my $entryExprXPATH = "entry";
    if ( $usingSimpleTable ) {
        $rowExprXPATH   = "strow";
        $entryExprXPATH = "stentry";
    }
    my @bodyRows = $tableNode->findnodes( $rowExprXPATH );
    my $logger = Log::Log4perl->get_logger("logger");

    ROW:
    for my $bodyRow (@bodyRows) {
        my @entries = $bodyRow->findnodes( $entryExprXPATH );
        unless ( @entries > 0 ) {
          my $msg = "Skipping row with no cells in $fName";
          $logger->warn( "$run:   $msg\n" );
          say STDERR $msg;
          next ROW;
        }
        my $rowDateString = $entries[0]->textContent;
        # This test is supposed to skip rows with no content, but it's
        #   only checking for an empty date. Improve it.
        unless ( $rowDateString =~ /\S/ ) {
            $logger->warn( "$run:   Row with empty/no date in $fName: value $rowDateString\n" );
            $bodyRow->unbindNode();
            next ROW;
        }
        my $rowDate = ParseDate($rowDateString);
        if ( $rowDate !~ /\S/ ) {
            print STDERR "Bad date \"$rowDateString\" found in file " . $fName . "\n";
            taintRow( $bodyRow );
            $logger->warn( "$run:   Tainted row in $fName: value $rowDateString\n" );
            next ROW;
        }
        my $f1 = Date_Cmp( $rowDate, $DATE_START_P );
        my $f2 = Date_Cmp( $rowDate, $DATE_END_P );
        if ( Date_Cmp( $rowDate, $DATE_START_P ) < 0 ) {
            # out of range - kill the row, goto next
            $bodyRow->unbindNode();
            next ROW;
        }
        if ( Date_Cmp( $rowDate, $DATE_END_P ) > 0 ) {
            $bodyRow->unbindNode();
            next ROW;
        }
    }
}

sub writeTopic {
    my $target = shift;
    my $tableWhole = shift;
    my $tableFixed = shift;
    my $topicTitle = shift;
    my $idNum = int( rand( 10000000)) + 10001;

    my $topicShell1 = <<ENDTOPICSHELL1;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE topic PUBLIC "-//FSL//DTD DITA Topic//EN" "FSL--DTD-DITA-Topic--EN.dtd">
<topic id="topic-$idNum">\n $topicTitle\n  <body>
ENDTOPICSHELL1

    my $topicShell2 = <<ENDTOPICSHELL2;
  </body>\n</topic>
ENDTOPICSHELL2

    open ( $outputFH, ">", $target ) or die "Can't open $target\n";
    print $outputFH $topicShell1;
    #
    #   Here's where the fun is
    #
    # temporary:
    writeTables( $tableWhole, $tableFixed );
    #
    #
    print $outputFH $topicShell2;
    close ( $outputFH );

}

sub killCols {
    for $ix (0..$#_) {
        $_[$ix]->unbindNode() unless substr( $preservedCols, $ix, 1 ) eq '1';
    }
}

sub fixExternalTableST {
    my $newTable = shift;
    my $ix;
    my @headings = $newTable->findnodes( "sthead/stentry" );    # risky
    killCols( @headings );

    my @rows = $newTable->findnodes( "strow" );
    for my $row (@rows) {
        my @entries = $row->findnodes( "stentry" );
        killCols( @entries );
    }
}

# no error checking at all!
#
sub fixExternalTable {
    my $newTable = shift;
    my $ix;

    my @colspecs = $newTable->findnodes( "tgroup/colspec" );
    killCols( @colspecs );

    my @headings = $newTable->findnodes( "tgroup/thead/row/entry" );    # risky
    killCols( @headings );

    my @rows = $newTable->findnodes( "tgroup/tbody/row" );
    for my $row (@rows) {
        my @entries = $row->findnodes( "entry" );
        killCols( @entries );
    }
}

sub writeTables {
    my $tableWhole = shift;             # original table unfiltered
    my $tableFiltered = shift;          # original table filtered by date
    my $tableSerialized;
    my $pTagString;                     # used for open p tag for no-changes string output

    my $logger = Log::Log4perl->get_logger("logger");

    # 2012/01/16: changing order of tables: output table, filtered table, original table
    #       also emending output of "no changes" message so it always appears (but marked 'internal' if there's a table as well)

    my $newTable =  $tableFiltered->cloneNode( 1 );             # copy filtered table for column-filtered version (deep copy == 1)
    $tableFiltered->setAttribute( "audience", "internal" );     # hide filtered table
    $tableWhole->setAttribute( "audience", "internal" );        # hide original table

    # set flags and variables if filtered table has ID attribute
    if ( $tableFiltered->hasAttribute( "id" ) ) {
        $IDval = $tableFiltered->getAttribute( "id" );
        $newTable->setAttribute(   "id", $IDval . "_COPY" );
        $tableWhole->setAttribute( "id", $IDval . "_ORIGINAL" );
    }

    # now remove unwanted columns from output table
	
	#################### Modified by Niraj Gandhi - B49052 ##################################################  
	# my $cols = $internalFlag ? 5 : 2;
	my $cols = $internalFlag ? 3 : 2; # Generates three columns for internal and two for customer versions
	if ($cols == 2) # For customer version, no internal description.
		{
			$no_internal_desc = 1;
		}
	#########################################################################################################

    set_tgroupColumns( $newTable, $cols ) unless $usingSimpleTable;
    $usingSimpleTable ?  fixExternalTableST( $newTable ): fixExternalTable( $newTable );
    fixTableHeadings( $newTable );

    if ( stillHasRows( $tableFiltered ) ) {
        # now output: first the no-changes statement, conditionalized appropriately (in case it's needed)
        #           then the final table, filtered by row and column
        print $outputFH "\n    <p audience='internal'>${noChangesMessage}</p>\n\n";
        $tableSerialized = encode('UTF-8', $newTable->toString( 1 ));
        $tableSerialized =~ s/^\s+$//mg;
        print $outputFH "\n$tableSerialized\n";
        $logger->trace( "\n\n-- Output table start\n\n$tableSerialized\n--  Output table end\n\n" );

        # next the filtered table
        $tableSerialized = encode('UTF-8', $tableFiltered->toString( 1 ));
        $tableSerialized =~ s/^\s+$//mg;
        $logger->trace( "\n\n-- Filtered table with all columns start\n\n$tableSerialized\n--  Filtered table with all columns end\n\n" );
    }
    else {
        print $outputFH "\n    <p>${noChangesMessage}</p>\n";
        $logger->trace( "\n    <p>${noChangesMessage}</p>\n\n" );
    }

    # finally log the whole (original) table
#    $tableSerialized = encode('UTF-8', $tableWhole->toString( 1 ));
#    $logger->debug( "\n\n-- Original table start\n\n$tableSerialized\n--  Original table end\n\n" );
#   # removed 2013/03/05
}

sub set_tgroupColumns {
    my $newTable = shift;
    my $columnCount = shift;
    my @tgroups = $newTable->findnodes( "tgroup" );
    die "no tgroup elements found" unless @tgroups > 0;
    $tgroups[0]->setAttribute( "cols", $columnCount );
}

sub fixTableHeadings {

	###################################### Modified by Niraj Gandhi - b49052 ######################################
	#    my @newHeadTitles = qw( Reference Description );
	my @newHeadTitles = qw( Reference Internal-Description Description ); # column head for internal versions
	###############################################################################################################

    my $tableNode = shift;
    my $headPathExpr = $usingSimpleTable ? "sthead/stentry" : "tgroup/thead/row/entry";
    my @heads = $tableNode->findnodes( $headPathExpr );
    return if @heads == 0;
    for my $head (@heads) {
        my $newHead = XML::LibXML::Element->new( $usingSimpleTable ? "stentry" : "entry" );
        my $newText = shift( @newHeadTitles );
	################### Modified by Niraj Gandhi - b49052 ###################################
		if ($no_internal_desc == 1)
		{
			my $newText = shift( @newHeadTitles ); # shifts column head for customer versions
		}
	#######################################################################################
        $newHead->appendTextNode( $newText );
        $head->replaceNode($newHead);
    }
}

sub stillHasRows {
    my $tableNode = shift;
    my $rowExprXPATH = $usingSimpleTable ?  "strow" : "tgroup/tbody/row";
    my @rows = $tableNode->findnodes( $rowExprXPATH );
    return( @rows > 0 );
}

sub getFileName {
    my $oldPath = shift;
    my @oldPath = split( "/", $oldPath );
    my $file = pop @oldPath;
    return $file;
}

sub openTopic {
    my $topicPath = shift;
    my @parts = split "/", $topicPath;
    my $topicFile = pop @parts;
    my $topicSource = openFile ( join("/",@parts), $topicFile );
    my $topicTree = $parser->parse_string( $topicSource );
}

# Searches in . for a document with top-level element containing
#       @id = 'RH_output'.
#
sub findSourceDoc {
  say STDERR "Looking for source document(s)....";
  my @grep = <*.xml>;
  for $file ( @grep ) {
    say STDERR "   ... found $file";
    my $topicSource = openFile( '.', $file );
    my $topicTree = $parser->parse_string( $topicSource );
    my $root = $topicTree->documentElement();
    my $tid = $root->getAttribute( 'id' );
    push( @mapsFound, $file ) if $tid eq 'RH_output';
  }
}

sub openFile {
    my $path = shift;
    my $doc  = shift;
    my $file = $path . '/' . $doc;
    my $docSource;

    open( SOURCE, "< $file") or die "Can't open file $file: $!\n";

    {
        local $/;
        $docSource = decode('UTF-8', <SOURCE>);
        close SOURCE;
    }
    $docSource;
}

####################### Modified by Niraj Gandhi-b49052 #######################
# It searches the revision history topics with no updates. Then it modifies the revision history map by marking these topics as internal.
delNoRev();

sub delNoRev
{
	
		#$tempN = $outputDir . "/$outputMapName.xml";
		open(ListOfNoRev,">files_no_rev_history.txt") or die "can't create a file.";
		opendir(DIR, "$outputDir/topics") or die "cannot open directory";
		@docs = grep(/\.xml$/,readdir(DIR));
		#print(@docs);
		foreach $file (@docs) 
		{
			open (RES, "$outputDir/topics/$file") or die "could not open $file\n";
			while($nochange = <RES>)
			{	
				#$nochange=chomp($nochange);
				$msg = "<p>$noChangesMessage</p>";
				if ($nochange =~ /$msg/)
				{
					#system("$file >> files_no_rev_history.txt");
					print ListOfNoRev "$file\n";
					last;
				}
			}
			close(RES);
		}	
		close(ListOfNoRev);
		
		$oldmap_path = "$outputDir/$outputMapName.xml";
		
		open(Old_Map,"$oldmap_path") or die "can't open the map file.";
		
        @oldmap = <Old_Map>;
        
        close(Old_Map);

        #print "@oldmap \n";
        
        open(NoRev,"files_no_rev_history.txt");

        while($read_norev = <NoRev>)
		{
			chop($read_norev);
            #chop($read_norev);
            #print("$read_norev");
            for ($count = 1; $count <= @oldmap; $count++) 
            {
                if ($oldmap[$count-1] =~ /$read_norev/) 
                {
                    #print("flag = 1 \n");
                    $oldmap[$count-1] =~ s/topicref/topicref\ audience="internal"/g;
                }
            }
        }   
        
        close(NoRev);
		
		open(New_Map,">$oldmap_path") or die "can't open the map file.";
		print New_Map "@oldmap";
		close(New_Map);
}		
################################################################################
=cut

#        print $outputFH "      <topicref href='topics/" . ${topicref} . "'/>\n";

Log levels:
    TRACE
    DEBUG
    INFO
    WARN
    ERROR
    FATAL

Column contents
  date
  person
  xref
  attributes
  internal
  external
  unused

#   known issues, 2012/02/11:
#       when date is empty, should check for other empty cells
#       maybe: should check length of all date strings (in case of 12/12, which is parsed as 12/12/<year>)
#       non-empty filtered table sometimes results in empty table if filtering removes remaining rows
#       select attributes on map now supported, but only top level
#           need to issue message for s-atts on children
#           writeMap modifies source map nodes (which are then discarded)

# notes:
#     should we output a single file??
#

=cut

=cut  revision history

#
# 2013/02/06: began work on new version (see notes at top of file)
# 2013/02/11: added (turned on, since it was inherited from rh01) simpletable support;
#               now copies select atts onto map entries (required XQuery update)
# 2013/02/13: fixed appendTo problem in nested topics (writeAllTopics) 
# 2013/02/18: added findSourceDoc to find map only in .
# 2013/03/01: updated checkArgs to support an optional 4th parameter, as follows:
#              -it must be either 'X' or 'x'; otherwise the script aborts
#              -if the user enters either 'x' or 'X' as the 4th parm, internal columns are produced
#             updated writeTables to write the correct column count into tgroup/@cols
#             updated writeIntroTopic to embed the date range into a hidden p element
# 2013/03/05: removed logging of full tables - no longer useful due to the way the source file
#             is generated and its location; other minor logging and display refinements
# 2013/03/12: replaced parm 1 $hrefOutput with $topicName in call to killRows in sub 
#             writeAllTopics (fixes error reporting in case bad date found)
#             Also, in killRows, replaced $rowDate (parsed date) with $rowDateString 
#             (raw date string) in error message
#             Refined logging (& removed most)
# 2013/03/19: added check in issueReports for //xref/@href="MMO_RESOURCE_TYPE"
# 2013/03/21: removed use of XPATHHelper.pm - will add normalize_space if needed later
# 2013/04/04: added test for no cells in [simpletable] row in killRows (skip & log if no cells in row)
#
# 2015/02/04: Marked modification with # Modified by Niraj Gandhi - b49052 #. Changes include:
#			  1. Looks for the topics with no updates and mark these as internal in the revision history map file. 
#			  2. Ensures no blank columns are displayed in the final revision history.
#
# 2015/10/16: Marked modification with # Modified by Niraj Gandhi - b49052 #. Change includes:
#			  1. Displays checked out XML rivision history file name which has no table title. (table title: (<table><title></title></table>).)
#
=cut
