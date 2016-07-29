#!/usr/bin/perl

use strict ;
use warnings ;

use utf8 ;
use JSON::XS ;
use Furl ;
use Term::ProgressBar ;

binmode(STDIN, ":utf8") ;
binmode(STDOUT, ":utf8") ;

# tmdb_full : Récupère les titres alternatifs pour chaque film répertorié par The Movie Database

# Création d'un objet Furl pour faire les requêtes HTML
my $furl = Furl->new(
        agent   => 'TMDB',
        timeout => 10,
    );

#Cherche le dernier film ajouté à TMDB
my $latest_request = $furl->get("http://api.themoviedb.org/3/movie/latest?api_key=87f32dd36ec4c41637e782a082c9f098") ;
# Création d'un parser JSON à partir de l'output de la requête précédente 
my $latest_parser = decode_json $latest_request->content ;
# Récupération de l'id TMDB du dernier film ajouté à TMDB
my $latest_id = $latest_parser->{'id'} ;

# Ouverture et initialisation du fichier d'output final
open(XML, '>', 'tmdb_output.xml') ;
binmode(XML, ":utf8") ;
print XML '<?xml version="1.0" encoding="UTF-8"?>'."\n" ;
print XML '<rdf:RDF xmlns:skos="http://www.w3.org/2004/02/skos/core#"
         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'."\n" ;

# Récupération du timestamp du début de l'extraction
my $start = time() ;
# Création d'une barre de progression
my $progress = Term::ProgressBar->new($latest_id) ;

my $id = 0 ;

my %language_table = ( 'AD' => 'ca' , # Andorre
					   'AE' => 'ar' , # Emirats Arabes Unis
					   'AL' => 'sq' , # Albanie
					   'AM' => 'hy' , # Arménie
					   'AR' => 'es' , # Argentine
					   'AS' => 'en' , # Samoa Américaines
					   'AT' => 'de' , # Autriche
					   'AU' => 'en' , # Australie
					   'AW' => 'nl' , # Aruba
					   'AZ' => 'az' , # Azerbaïdjan
					   'BD' => 'bn' , # Bengladesh
					   'BF' => 'fr' , # Burkina Faso
					   'BG' => 'bg' , # Bulgare
					   'BH' => 'ar' , # Bahreïn
					   'BO' => 'es' , # Bolivie**
					   'BR' => 'pt' , # Brésil
					   'BY' => 'be' , # Biélorussie
					   'CL' => 'es' , # Chili
					   'CN' => 'zh' , # Chine
					   'CR' => 'es' , # Costa Rica
					   'CU' => 'es' , # Cuba
					   'CZ' => 'cz' , # République Tchèque
					   'CO' => 'es' , # Colombie
					   'DE' => 'de' , # Allemagne
					   'DK' => 'dk' , # Danemark
					   'DO' => 'es' , # République Dominicaine
					   'EE' => 'et' , # Estonie
					   'EC' => 'es' , # Equateur
					   'EG' => 'ar' , # Egypte
					   'ES' => 'es' , # Espagne
					   'FI' => 'fi' , # Finlande
					   'FR' => 'fr' , # France
					   'GB' => 'en' , # Royaume-Uni
					   'GD' => 'fr' , # Grenada
					   'GE' => 'ka' , # Géorgie
					   'GF' => 'fr' , # Guyane Française
					   'GH' => 'en' , # Ghana
					   'GL' => 'kl' , # Groënland
					   'GR' => 'el' , # Grec
					   'GT' => 'es' , # Guatemala
					   'GU' => 'en' , # Guam
					   'HK' => 'hk' , # Hong-Kong
					   'HN' => 'es' , # Honduras
					   'HR' => 'hr' , # Croatie
					   'HU' => 'hu' , # Hongrie
					   'ID' => 'id' , # Indonésie
					   'IE' => 'en' , # Irlande
					   'IL' => 'he' , # Israël
					   'IQ' => 'ar' , # Irak
					   'IR' => 'fa' , # Iran
					   'IT' => 'it' , # Italie
					   'IS' => 'is' , # Islande
					   'JM' => 'en' , # Jamaïque
					   'JP' => 'jp' , # Japon
					   'KH' => 'kh' , # Cambodge
					   'KP' => 'ko' , # Corée du Nord
					   'KR' => 'ko' , # Corée du Sud
					   'KZ' => 'kk' , # Kazakhstan
					   'LB' => 'ar' , # Liban
					   'LK' => 'si' , # Sri Lanka 
					   'LT' => 'lt' , # Lituanien
					   'LV' => 'lv' , # Letton
					   'MK' => 'mk' , # Macédoine
					   'ML' => 'fr' , # Mali
					   'MX' => 'es' , # Mexique
					   'MW' => 'ny' , # Malawi
					   'MY' => 'ms' , # Malaisie
					   'NL' => 'nl' , # Pays-Bas
					   'NO' => 'no' , # Norvège
					   'NZ' => 'en' , # Nouvelle-Zélande
					   'PA' => 'es' , # Panama
					   'PE' => 'pe' , # Pérou
					   'PK' => 'ur' , # Pakistan
					   'PL' => 'pl' , # Pologne
					   'PH' => 'fil', # Philippines
					   'PS' => 'ar' , # Palestine
					   'PT' => 'pt' , # Portugal
					   'PR' => 'es' , # Porto Rico
					   'RO' => 'ro' , # Roumain
					   'RS' => 'sr' , # Serbie
					   'RU' => 'ru' , # Russie
					   'SA' => 'ar' , # Arabie Saoudite
					   'SE' => 'se' , # Suède
					   'SI' => 'sl' , # Slovénie 
					   'SK' => 'sk' , # Slovaquie
					   'SN' => 'fr' , # Sénégal
					   'SV' => 'sv' , # Salvador
					   'SY' => 'ar' , # Syrie
					   'SZ' => 'sz' , # Swazilan
					   'TF' => 'fr' , # Terres australes et antarctiques françaises
					   'TH' => 'th' , # Thaïlande
					   'TR' => 'tr' , # Turquie
					   'TW' => 'zh' , # Taiwan
					   'UA' => 'uk' , # Ukraine
					   'UM' => 'en' , # Îles mineures éloignées des Etats-Unis
					   'UR' => 'es' , # Uruguay
					   'US' => 'en' , # Etats-Unis
					   'UZ' => 'uz' , # Ouzbékistan
					   'VE' => 'es' , # Venezuela
					   'VI' => 'en' , # Îles Vierges des Etats-Unis
					   'VN' => 'vi' , # Vietnam
					   'WS' => 'sm' , # Samoa
					   'ZA' => 'en'); # Afrique du Sud

my %verif = () ;

while ($id <= $latest_id)
{
	# Récupération des titres alternatifs du film
	my $request = $furl->get("https://api.themoviedb.org/3/movie/$id/alternative_titles?api_key=87f32dd36ec4c41637e782a082c9f098") ;
	my $request_parser = decode_json $request->content ;

	if ($request_parser->{'status_code'} ||
		$request_parser->{'titles'} eq '')
	{
		$progress->update($id) ;
		$id++ ;
		next ;
	}
	# Impression des résultats dans le fichier d'output 
	print XML "\t<skos:Concept rdf:about=\""."https://www.themoviedb.org/movie/$id"."\">\n" ;
	foreach my $value (@{$request_parser->{'titles'}})
	{
		if (exists $language_table{$value->{'iso_3166_1'}})
		{
			my $iso = $language_table{$value->{'iso_3166_1'}} ;
			if (exists $verif{$iso})
			{
				print XML "\t\t<skos:altLabel xml:lang=\"".$iso."\">".$value->{'title'}."</skos:altLabel>\n" ;
			}
			else
			{
				print XML "\t\t<skos:prefLabel xml:lang=\"".$iso."\">".$value->{'title'}."</skos:prefLabel>\n" ;
				$verif{$iso} = 1 ;
			}
		}
		else
		{
			next ;
		}
	}
	%verif = () ;
	print XML "\t</skos:Concept>\n" ;
	$id++ ;
}

print XML "</rdf:RDF>\n" ;
close XML ;

my $end = time() ;
my $elapsed = $end-$start ;
my $minutes = $elapsed / 60 ;

print "Temps écoulé : ".$minutes." minutes.\n" ;
