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
    my $dom = Mojo::DOM->new($content, charset => 'UTF-8');
    my %response = (
        domain => $domain,
        available => $dom->at('table.tablabusqueda td')->text eq $domain ? 0 : 1,
        owner => "",
        expiration => "",
    );
    if (!$response{available}) {
        my $owner = $dom->at("table.tablabusqueda tr:nth-child(2) td div:nth-child(2)")->text;
        my $expiration_dom = $dom->at("table.tablabusqueda tr:nth-child(6) td div:nth-child(2)");
        my $expiration;
        if ($expiration_dom) {
            $expiration = $expiration_dom->text;
        } else {
            $expiration = 'in deleting process';
        }
        $owner =~ s/^\s+|\s+$//g;
        $expiration =~ s/^\s+|\s+$//g;
        $response{owner} = $owner;
        $response{expiration} = $expiration;
    }
    return %response;
}

1;