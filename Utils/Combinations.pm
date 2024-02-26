package Utils::Combinations;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(generate_combinations);

sub generate_combinations {
    my ($set, $combo_length, $current_combo, $all_combos) = @_;

    # If the current combination is of the desired length, add it to the list of all combinations
    if (scalar(@$current_combo) == $combo_length) {
        push @$all_combos, [@$current_combo];
        return;
    }

    # Recursively generate combinations by adding each element of the set
    for my $element (@$set) {
        push @$current_combo, $element; # Add element to the current combination
        generate_combinations($set, $combo_length, $current_combo, $all_combos); # Recursive call
        pop @$current_combo; # Remove the last element to try the next possibility
    }
}

1;