package Utils::Combinations;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(generate_multiple_len_combos);

our @chars = ('a'..'z', '0'..'9');


sub generate_combinations {
    my ($length) = @_;

    # Internal recursive subroutine to handle variation generation
    my $generate;
    $generate = sub {
        my ($prefix, $n) = @_;
        return $prefix if $n == 0; # Base case: when length is reached

        my @results;
        foreach my $char (@chars) {
            push @results, $generate->($prefix . $char, $n - 1); # Recursive step
        }
        return @results;
    };

    return $generate->('', $length); # Start the recursive generation with an empty prefix
}

sub generate_multiple_len_combos {
    my ($min_len, $max_len) = @_;
    print "Generating combinations of length ($min_len,$max_len)\n";
    my @combos;

    my $combo_length = $min_len;
    while ($combo_length <= $max_len) {
        push @combos, generate_combinations($combo_length);
        $combo_length++;
    }
    printf(
        "Combinations of length (%s,%s): %s\n",
        $min_len,
        $max_len,
        scalar @combos
    );
    return @combos;
}

1;