package Utils::Files;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(store_array);


sub store_array {
    my ($filename, $array) = @_;

    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    for my $element (@$array) {
        my $line = join('', @$element);
        print $fh "$line\n";
    }
    close $fh;
}