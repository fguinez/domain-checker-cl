package Scraper;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use URI;
use Mojo::DOM;

sub new {
    my ($class) = @_;

    my $self = {
        url => 'https://www.nic.cl/registry/Whois.do',
    };

    bless $self, $class;
    return $self;
}

sub _find_in_table {
    my ($self, $table_class, $row_text) = @_;
    # find all the tr div elements in the table (names of the fields)
    my @names = $self->{dom}->find("table$table_class tr td div:nth-child(1) b")->each;
    my $row_name = (grep { $_->text eq $row_text } @names)[0];
    if (! $row_name) {
        return undef;
    }
    # get the next div (row value)
    my $row_value = $row_name->parent->next->text;
    $row_value =~ s/^\s+|\s+$//g;
    return $row_value;
}

sub scrape {
    my ($self, $domain) = @_;

    # check if domain ends with .cl
    if ($domain !~ m/\.cl$/) {
        $domain = $domain . '.cl';
    }

    my $uri = URI->new($self->{url});
    $uri->query_form(
        d => $domain,
    );
    my $ua = LWP::UserAgent->new;
    $ua->timeout(30);
    my $request = HTTP::Request->new(GET => $uri);
    $request->header('User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0');
    $request->header('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8');
    $request->header('Accept-Language' => 'en-GB,en;q=0.7,es;q=0.3');
    $request->header('Accept-Encoding' => 'gzip, deflate, br');
    $request->header('Referer' => 'https://www.nic.cl/registry/BuscarDominio.do');
    $request->header('Connection' => 'keep-alive');
    $request->header('Upgrade-Insecure-Requests' => '1');
    $request->header('Sec-Fetch-Dest' => 'document');
    $request->header('Sec-Fetch-Mode' => 'navigate');
    $request->header('Sec-Fetch-Site' => 'same-origin');
    my $response = $ua->request($request);

    if (! $response->is_success) {
        die "Failed: " . $response->status_line;
    }
    my $content = $response->decoded_content;
    $self->{dom} = Mojo::DOM->new($content, charset => 'UTF-8');
    my %response = (
        domain => $domain,
        available => $self->{dom}->at('table.tablabusqueda td')->text eq $domain ? 0 : 1,
        owner => "",
        creation => "",
        modification => "",
        expiration => "",
        in_delete_process => 0,
    );
    if (!$response{available}) {
        my $weird_o = chr(243);
        my $ weird_u = chr(250);
        my $owner = $self->_find_in_table(".tablabusqueda", "Titular:");
        my $creation = $self->_find_in_table(".tablabusqueda", "Fecha de creaci" . $weird_o . "n:");
        my $modification = $self->_find_in_table(".tablabusqueda", "Fecha de " . $weird_u . "ltima modificaci" . $weird_o . "n:");
        my $expiration = $self->_find_in_table(".tablabusqueda", "Fecha de expiraci" . $weird_o . "n:");
        $response{owner} = $owner;
        $response{creation} = $creation;
        $response{modification} = $modification;
        if ($expiration) {
            $response{expiration} = $expiration;
        } else {
            $response{in_delete_process} = 1;
        }
    }
    return %response;
}

1;