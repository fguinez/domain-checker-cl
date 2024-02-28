#!/usr/bin/perl

use strict;
use warnings;

use lib '.';
use Array::Utils qw(array_minus);
use Digest::MD5 qw(md5_hex);
use File::Path qw(remove_tree);
use Getopt::Long;
use Scraper;
use Try::Tiny;
use Utils::Combinations qw(generate_multiple_len_combos);
use Utils::Files qw(store_array file_to_array add_hash_to_csv read_csv);

# Global variables
our $PROGRESS_DIR = 'progress';
our $scraper = Scraper->new();

# Command line options
my $filename;
my $comb_min_len;
my $comb_max_len;
GetOptions(
    'filename|f=s' => \$filename,
    'comb_len|cl=s'  => \$comb_min_len,
);
my $usage = "Usage: perl main.pl filename.txt\n" .
            "       perl main.pl --filename=filename.txt\n" .
            "       perl main.pl -f filename.txt\n" .
            "       perl main.pl --comb_len=3\n" .
            "       perl main.pl -cl 3\n" .
            "       perl main.pl -cl '2,4'\n" .
            "\nParameters:\n" .
            "   filename: file containing the list of options\n" .
            "   comb_len: length of the combinations to generate. can be a " .
            "single number or a range, always lower than 5 (e.g. '2,4' " .
            "includes lengths 2, 3 and 4)\n\n" .
            "This script does not support comb_len options combined with " .
            "filename\n";
# Handling the positional argument case
$filename = defined $filename ? $filename : shift @ARGV;
# If no options provided, and no ARGV, it's an error
die $usage if !$filename && !$comb_min_len;
# If both filename and comb_len options are provided, it's an error
die $usage if $filename && $comb_min_len;
# Additional condition to ensure no extra arguments are passed
die $usage if @ARGV > 0;
# Parsing the comb_len options
if ($comb_min_len) {
    if ($comb_min_len =~ /(\d+),(\d+)/) {
        $comb_min_len = $1;
        $comb_max_len = $2;
    } else {
        $comb_max_len = $comb_min_len;
    }
    $comb_min_len = int($comb_min_len);
    $comb_max_len = int($comb_max_len);
    die $usage if $comb_min_len < 1 || $comb_max_len < 1 || $comb_min_len > $comb_max_len;
    die $usage if $comb_max_len > 4;
}

my @options;
my @checked;
my @pending;

my $dir;

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
    if (defined $filename) {
        @options = file_to_array($filename);
        # quit accents
        @options = map { s/á/a/g; s/é/e/g; s/í/i/g; s/ó/o/g; s/ú/u/g; $_ } @options;
        # ñ -> n
        @options = map { s/ñ/n/g; $_ } @options;
        # quit non-alphanumeric characters
        @options = map { s/[^a-zA-Z0-9]//g; $_ } @options;
    } else {
        @options = generate_multiple_len_combos($comb_min_len, $comb_max_len);
    };
    my $checksum = md5_hex(@options);
    $dir = "$PROGRESS_DIR/$checksum";
    mkdir $dir;
    store_array("$dir/options.txt", @options);
    print "Progress available in $dir\n";
    @checked = read_csv("$dir/chequed.csv");
    @checked = map { substr($_->{'domain'}, 0, -3) } @checked;
    @pending = array_minus(@options, @checked);
    print "All options: " . scalar @options . "\n";
    print "Checked: " . scalar @checked . "\n";
    print "Pending: " . scalar @pending . "\n";
}

sub check_combination {
    my ($combination) = @_;
    my $domain = "$combination.cl";
    print "Checking $domain\n";
    my %response = $scraper->scrape($domain);
    add_hash_to_csv("$PROGRESS_DIR/chequed.csv", %response);
    add_hash_to_csv("$dir/chequed.csv", %response);
    if ($response{'available'}) {
        add_hash_to_csv("$PROGRESS_DIR/available.csv", %response);
        add_hash_to_csv("$dir/available.csv", %response);
        print "AVAILABLE: $domain\n";
    } elsif ($response{'in_delete_process'}) {
        add_hash_to_csv("$PROGRESS_DIR/in_delete_process.csv", %response);
        add_hash_to_csv("$dir/in_delete_process.csv", %response);
        print "IN DELETE PROCESS: $domain\n";
    } else {
        add_hash_to_csv("$PROGRESS_DIR/unavailable.csv", %response);
        add_hash_to_csv("$dir/unavailable.csv", %response);
    }
}

sub run {
    if (no_previous_progress()) {
        set_up_progress_dir();
    }
    restore_progress();
    for my $combination (@pending) {
        my $tries = 3;
        my $success = 0;
        while ($tries > 0 && !$success) {
            try {
                check_combination($combination);
                $success = 1;
            } catch {
                $tries--;
                print "Failed: $_ ($tries remaining)\n";
                my $random_seconds = 50 + int(rand(21));
                print "Waiting $random_seconds seconds\n";
                sleep $random_seconds;
            };
        };
    }
    print "Done. Results stored in $dir. " . scalar @options . " domains checked.\n";
}

run();