use strict;
use warnings;

use lib '.';
use Utils::Combinations qw(generate_combinations);
use Utils::Files qw(store_array);


my @chars = ('a'..'z', '0'..'9');
my $combo_length = 3;

my @all_combos;

my $init_combo_length = $combo_length;
while ($combo_length > 0) {
    generate_combinations(\@chars, $combo_length, [], \@all_combos);
    $combo_length--;
}

@all_combos = sort { scalar(@$a) <=> scalar(@$b) } @all_combos;




printf(
    "Combinations of length %s or less: %s\n",
    $init_combo_length,
    scalar @all_combos
);


my $filename = 'combinations.txt';

store_array($filename, \@all_combos);
print "Stored in $filename\n";