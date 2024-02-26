use strict;
use warnings;

use lib '.';
use Utils::Combinations qw(generate_combinations);


my @chars = ('a'..'z', '0'..'9');
my $combo_length = 3;
my @all_combos;

while ($combo_length > 0) {
    generate_combinations(\@chars, $combo_length, [], \@all_combos);
    $combo_length--;
}

@all_combos = sort { scalar(@$a) <=> scalar(@$b) } @all_combos;



for my $combo (@all_combos) {
    printf(
        "%s\n",
        join('', @$combo)
    );
}

printf(
    "All combinations of length %s: %s\n",
    $combo_length,
    scalar @all_combos
);