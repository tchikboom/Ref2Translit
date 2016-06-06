#!/usr/bin/perl

use WWW::Mechanize;
use Data::Dumper;
use JSON;
use utf8;
use XML::LibXML;

binmode(STDOUT, ":utf8");

#Initialisation du endpoint
my $endpoint = "http://viaf.org/viaf/";

#Récupère l'entrée utilisateur
print "Quelle entité voulez-vous rechercher ?\n";
chomp(my $recherche = <STDIN>);
#$recherche =~ s/\s/_/g;

#Initialisation de l'opération
my $operation = "AutoSuggest?query=$recherche";

#Initialisation de Mechanize
my $mech = WWW::Mechanize->new();
$mech -> cookie_jar(HTTP::Cookies->new());

#Requête
$mech -> get($endpoint.$operation);

#Transformation du JSON en structure perl, décortication et déréférencements
my $ref = decode_json($mech->content( format => 'text' ));
my %json = %$ref;
my $ref = $json{'result'};
my @results = @$ref;

#Impression des résultats de la recherche et sélection
print "Cherchiez-vous...\n";
my $i=1;
my %selection;
foreach $ref (@results) {
	my %result = %$ref;
	my $viafid = $result{"viafid"};
	my $displayForm = $result{"displayForm"};
	$selection{$i} = $viafid;
	print "$i.\t$displayForm\n";
	$i++;
}
print "Sélection : ";
chomp(my $num = <STDIN>);

#Constitution de l'url de l'entité désirée
$operation = $selection{$num}.'/';

#Initialisation du parser XML
$parser = XML::LibXML->new();
$xml = XML::LibXML->load_xml(
	location => $endpoint.$operation
);

#Boucle sur les différentes formes
my %tableFormes;
for my $data ($xml->findnodes('/ns2:VIAFCluster/ns2:mainHeadings/ns2:data')) {
	
	my $form = $data->findvalue('./ns2:text');
	#Boucle sur les différentes langues utilisant cette forme et stockage dans le hash
	for my $source ($data->findnodes('./ns2:sources/ns2:s')) {
		my $lang = $source->textContent();
		$tableFormes{$lang} = $form;
	}
}

print Dumper (\%tableFormes);