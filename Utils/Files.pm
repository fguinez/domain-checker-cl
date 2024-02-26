package Utils::Files;

use strict;
use warnings;
use Text::CSV;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(store_array add_hash_to_csv);


sub store_array {
    my ($filename, $array) = @_;

    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    for my $element (@$array) {
        my $line = join('', @$element);
        print $fh "$line\n";
    }
    close $fh;
}

sub add_hash_to_csv {
    my ($filename, %hash) = @_;

    my $csv_exists = -e $filename;
    my @keys = sort keys %hash;

    open my $fh, '>>', $filename or die "Could not open '$filename' for writing: $!";
    binmode $fh, ":utf8"; # If you're dealing with Unicode characters
    my $csv = Text::CSV->new({
        binary => 1,
        auto_diag => 1,
        eol => "\n"
    }) or die "Cannot use CSV: " . Text::CSV->error_diag();
    if (!$csv_exists){
        # Write header row
        $csv->print($fh, \@keys);
    }
    # Write data row
    my @values = map { $hash{$_} } @keys;
    $csv->print($fh, \@values);

    close $fh;
}