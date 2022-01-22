

use strict;
use warnings;
use strict;
use XML::Twig;
our @file_list;
my $xml = <<XML;
<note>
				<topicref href="../regs/col1374600643854.regs"
                    type="reference"/>
                <topicref href="../regs/col1374600644815.regs" type="reference"/>
</note>
XML

my $twig = XML::Twig->new(twig_handlers => { topicref => \&getId });
$twig->parse($xml);

sub getId {
    my ($twig, $mod) = @_;
    my $to_id = $mod->att('href');
   push @file_list, $to_id;
}

my $file_name = "SBSX register descriptions"; #Change this as per requirement
my $string_value = $file_name;
$string_value =~ s/[\s+-]/_/g;

open(REGS_PPFE,">merged_registers.regs");

print REGS_PPFE "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<crr:UniversalDevice
  xsi:schemaLocation=\"http://apif.freescale.net/schemas/regs/1.3 http://apif.freescale.net/schemas/regs/1.3/regs.xsd\"
  xmlns:crr=\"http://apif.freescale.net/schemas/regs/1.3\"
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">


  <creation_info author=\"\$Author: B49052 \$\" date=\"\$Date\$\" revision=\"\$Revision\$\" source=\"\$Source\$\"/>
  <GeneralPeriphery>
    <GeneralParameters>
      <instance_header>
        <instance_description>$file_name</instance_description>
        <instance_long_description>
          
        </instance_long_description>
        <template_parameters>
          <!--<include_template_parameters file=\"../params/.paramdef\" format=\"XML\"/>   -->
        </template_parameters>
      </instance_header>
      <general_parameter_defs>
        <string_general_parameter name=\"peripheralType\" value=\"$string_value\"
          description=\"Peripheral/Component Type\"/>
      </general_parameter_defs>
    </GeneralParameters>

    <register_defs>

      <address_block name=\"$string_value\" byte_order=\"bigEndian\" lau=\"8\">

        <base_address/>
        <bit_order order=\"lsb0\"/>";

foreach my $input_xml_file (@file_list) 
{
	open(REG_FILE,"$input_xml_file");
	
	print REGS_PPFE "\n\n<!-- ======================= $input_xml_file ============================== -->\n\n";
	while (<REG_FILE>)
	{
		print REGS_PPFE "$_";

	}
	close(REG_FILE);
}

print REGS_PPFE "</address_block>

    </register_defs>
  </GeneralPeriphery>

</crr:UniversalDevice>
";
close(REGS_PPFE);