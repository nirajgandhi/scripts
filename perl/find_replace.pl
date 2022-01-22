
#!/usr/bin/perl
use warnings;
use strict;

open LOG, "conversion_success.log" or die;
my %hash;
while (my $line=<LOG>) {
   chomp($line);
   (my $old_file,my $new_file) = split /-->/, $line;
   $hash{$old_file} = $new_file;
}
use Data::Dumper;
print Dumper \%hash;

close (LOG);

