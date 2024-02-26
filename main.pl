use strict;
use warnings;

use lib '.';
use File::Path qw(remove_tree);
use Utils::Combinations qw(generate_combinations);
use Utils::Files qw(store_array);
use Scraper;


our $PROGRESS_DIR = 'progress';


my @chars = ('a'..'z', '0'..'9');
my $combo_length = 3;

my @all_combos;

sub init_process {
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

    my $filename = "$PROGRESS_DIR/combinations.txt";

    store_array($filename, \@all_combos);
    print "Stored in $filename\n";
}

sub check_progress {
    return -d $PROGRESS_DIR;
}

sub set_up_progress_dir {
    print "Reseting progress\n";
    remove_tree $PROGRESS_DIR;
    mkdir $PROGRESS_DIR;
    init_process();
}

sub restore_progress {
    print "Restoring progress\n";
    # TODO: Implement
}

sub run() {
    unless (check_progress()) {
        set_up_progress_dir();
    } else {
        restore_progress();
    }
    # TODO: Implement
    my $scraper = Scraper->new();
    my %response = $scraper->scrape('aaa.cl');
    while (my ($key, $value) = each %response) {
        print "$key: $value\n";
    }
}

run();