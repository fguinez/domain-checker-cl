use strict;
use warnings;

use lib '.';
use Array::Utils qw(array_diff);
use File::Path qw(remove_tree);
use Utils::Combinations qw(generate_combinations);
use Utils::Files qw(store_array file_to_array add_hash_to_csv read_csv);
use Scraper;



our $PROGRESS_DIR = 'progress';

our $scraper = Scraper->new();


my @chars = ('a'..'z', '0'..'9');
my $combo_length = 3;

my @all_combos;
my @checked_combos;
my @pending_combos;

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

sub no_previous_progress {
    return !-d $PROGRESS_DIR;
}

sub set_up_progress_dir {
    print "Reseting progress\n";
    remove_tree $PROGRESS_DIR;
    mkdir $PROGRESS_DIR;
    init_process();
}

sub restore_progress {
    print "Restoring progress\n";
    @all_combos = file_to_array("$PROGRESS_DIR/combinations.txt");
    @checked_combos = read_csv("$PROGRESS_DIR/all.csv");
    @checked_combos = map { substr($_->{'domain'}, 0, -3) } @checked_combos;
    @pending_combos = array_diff(@all_combos, @checked_combos);
    print "All: " . scalar @all_combos . "\n";
    print "Checked: " . scalar @checked_combos . "\n";
    print "Pending: " . scalar @pending_combos . "\n";
}

sub check_combination {
    my ($combination) = @_;
    my $domain = "$combination.cl";
    my %response = $scraper->scrape($domain);
    while (my ($key, $value) = each %response) {
        print "$key: $value\n";
    }
    add_hash_to_csv("$PROGRESS_DIR/all.csv", %response);
    if ($response{'available'}) {
        add_hash_to_csv("$PROGRESS_DIR/available.csv", %response);
    } else {
        add_hash_to_csv("$PROGRESS_DIR/unavailable.csv", %response);
    }
}

sub run {
    if (no_previous_progress()) {
        set_up_progress_dir();
    }
    restore_progress();
    for my $combination (@pending_combos) {
        check_combination($combination);
    }
    
}

run();