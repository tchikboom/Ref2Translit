#!/usr/bin/perl

#use WWW::Mechanize;
use Data::Dumper;
use JSON;
use utf8;
use XML::LibXML;
use WWW::Mechanize;
use LWP::Simple;
use Encode;
#use XML::Simple;
binmode(STDIN,  ":utf8");
binmode(STDOUT, ":utf8");



#=========================Main===============================

#Initialisation du endpoint
my $endpoint = "http://viaf.org/viaf/";

#Récupère l'entrée utilisateur
print "Quelle entité voulez-vous rechercher ?\n";
chomp(my $recherche = <STDIN>);

#Initialisation de l'opération
my $operation = "AutoSuggest?query=$recherche";

#Initialisation de Mechanize
my $mech = WWW::Mechanize->new();
$mech -> cookie_jar(HTTP::Cookies->new());

#Requête
$mech -> get($endpoint.$operation);
# my $mech = get($endpoint.$operation);

#Transformation du JSON en structure perl, décortication et déréférencements
my $ref = decode_json($mech->content( format => 'text' ));
# my $ref = decode_json($mech);
my %json = %$ref;
my $ref = $json{'result'};
my @results = @$ref;

#Fin du programme si aucun resultat n'est retourné
if (!@results) {
	print "Aucun résultat correspondant à \"$recherche\".\n";
	die;
};

#Impression des résultats de la recherche et sélection
print "Cherchiez-vous...\n";
my $i=0;
my %selection;
foreach $ref (@results) {
	$i++;
	my %result = %$ref;
	my $viafid = $result{"viafid"};
	my $displayForm = $result{"displayForm"};
	$selection{$i} = $viafid;
	print "$i.\t$displayForm\n";
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
	
	my $forme = $data->findvalue('./ns2:text');
	#Boucle sur les différentes sources utilisant cette forme
	for my $source ($data->findnodes('./ns2:sources/ns2:s')) {
		my $code = $source->textContent();
		my @liste = sourceEquivalence($code);
		foreach my $couple (@liste) {
			my ($source,$lang) = @$couple;
			push(@{$tableFormes{$lang}{$forme}},$source);
		}
	}
}
#print Dumper (\%tableFormes);

#Ecriture du XML
open (XML,">:encoding(utf8)","test.xml");

print XML "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<translit>\n\t<entite id=\"$recherche\">\n";

# my $xml = XML::LibXML::Document->new( "1.0", "utf-8" );
# my $root = $xml->createElement ("translit");
# $xml->setDocumentElement ($root);

# 	my $entité = $xml->createElement ("entite");
# 	$entité->addChild ($xml->createAttribute ( id => "$recherche") );


foreach my $langue (keys(%tableFormes)) {
	my %formes = %{$tableFormes{$langue}};
	foreach my $forme (keys(%formes)) {
		my @sources = @{$formes{$forme}};
		foreach my $source (@sources) {
			my $formeNode = $xml->createElement ("forme");
# 			$formeNode->addChild ($xml->createAttribute ( source => "$source") );
# 			$formeNode->addChild ($xml->createAttribute ( langue => "$langue") );
# 			$formeNode->addChild($xml->createTextNode($forme));
# 			$entité->addChild($formeNode);
			
			print XML "\t\t<forme source=\"$source\" langue=\"$langue\">$forme</forme>\n";
			
		}
	}
}

# 	$root->addChild($entité);
	
# $xml->setDocumentElement ($root);

# print XML $xml->toString(1);

print XML "\t</entite>\n</translit>";




#=========================Source équivalence===============================
sub sourceEquivalence {
	my ($code) = @_;
	my %equivalences = (	"NLP" => [["Biblioteka Narodowa" , "pl"]],
				"JPG" => [["Getty Research Institute" , "en"]],
			  	"KRNLK" => [["국립중앙도서관" , "ko"]],
			  	"N6I" => [["National Library of Ireland" , "en"]],
			  	"NUKAT" => [["Centrum NUKAT Biblioteki Uniwersyteckiej w Warszawie" , "pl"]],
			  	"PTBNP" => [["Biblioteca Nacional de Portugal" , "pt"]],
			  	"SUDOC" => [["Agence Bibliographique de l’Enseignement Supérieur" , "fr"]],
			  	"NLI" => [["הספרייה הלאומית" , "he"]],
			  	"LC" => [["Library of Congress" , "en"]],
			  	"NSK" => [["Nacionalna i sveučilišna knjižnica u Zagrebu" , "hr"]],
			  	"WKP" => [["Wikipedia" , "wk"]],
			  	"DBC" => [["Dansk BiblioteksCenter" , "da"]],
			  	"SELIBR" => [["Kungliga biblioteket - Sveriges nationalbibliotek" , "sv"]],
			  	"BNE" => [["Biblioteca Nacional de España" , "es"]],
			  	"BNF" => [["Bibliothèque nationale de France" , "fr"]],
			  	"LAC" => [["Library and Archives Canada" , "en"] , ["Bibliothèque et Archives Canada" , "fr"]],
			  	"BNC" => [["Biblioteca de Catalunya" , "ca"]],
			  	"BNCHL" => [["National Library of Chile" , "es"]],
			  	"ISNI" => [["International Standard Name Identifier" , "isni"]],
			  	"B2Q" => [["Bibliothèque et Archives nationales du Québec" , "fr"]],
			  	"NLA" => [["National Library of Australia" , "en"]],
			  	"SWNL" => [["Schweizerische Nationalbibliothek" , "de"] , ["Bibliothèque nationale suisse" , "fr"] , ["Biblioteca nazionale svizzera" , "it"]],
			  	"EGAXA" => [["مكتبة الاسكندرية" , "ar"]],
			  	"NLR" => [["National Library of Russia" , "ru"]],
			  	"NDL" => [["国立国会図書館" , "ja"]],
			  	"ICCU" => [["Istituto centrale per il Catalogo unico delle biblioteche italiane e per le informazioni bibliografiche" , "it"]],
			  	"BAV" => [["Biblioteca Apostolica Vaticana" , "la"]],
			  	"DNB" => [["Deutsche Nationalbibliothek" , "de"]],
			  	"NTA" => [["Koninklijke Bibliotheek" , "nl"]],
			  	"LNL" => [["المكتبة الوطنية اللبنانية" , "ar"]],
			  	"NKC" => [["Národní knihovna České republiky" , "cs"]],
			  	"LNB" => [["Latvijas Nacionālā bibliotēka" , "lv"]],
			  	"NSZL" => [["Országos Széchényi Könyvtár" , "hu"]],
			  	"RERO" => [["Réseau des bibliothèques de Suisse occidentale" , "fr"] , ["Réseau des bibliothèques de Suisse occidentale" , "de"]],
			  	"VLACC" => [["Vlaamse Centrale Catalogus" , "nl"]],
			  	"BIBSYS" => [["Nasjonalbiblioteket" , "no"]],
			  	"NLB" => [["National Library Board Singapore" , "en"]],
			  	"SRP" => [["Syriac Reference Portal" , "syc"]],
			  	"CYT" => [["國家圖書館" , "zh"]],
			  	"BNL" => [["Bibliothèque nationale de Luxembourg" , "fr"] , ["Nationalbibliothéik Lëtzebuerg" , "lb"]]
			   );
	my $liste = $equivalences{$code};
	return @$liste;
}