#!/usr/bin/perl

use strict ;
use warnings ;

use LWP::Simple ;
use XML::Simple ;

# Extraction des translitérations proposées par Geonames

# Récupère la requête de l'utilisateur
print "Entrer un lieu à chercher :\n" ;
chomp(my $req = <STDIN>) ;
if ($req eq ''){die "Vous n'avez pas entré de lieu à chercher. Veuillez recommencer.\n"};
# Minusculisation de la requête pour faciliter son traitement ultérieur
$req = lc($req) ;

# Effectue une requête HTML en fonction de l'input de l'utilisateur, et l'enregistre dans un fichier XML
# On demande 5 résultats pour éviter les cas où le lieu demandé n'est pas le premier trouvé par Geonames
my $url = "http://api.geonames.org/search?q=$req&maxRows=5&type=rdf&username=tchikboom";
open(REQ,'>','req_output.xml') ;
binmode(REQ, ":utf8") ;
print REQ get($url) ;
close REQ ;

# Création d'un parser XML à partir de l'output de la requête
my $xml = new XML::Simple ;
my $parser = $xml->XMLin("req_output.xml") ;

# Exemple résumé de structure XML du document :
# <gn:Feature>
# 	<gn:officialName xml:lang = "fr">Londres<gn:officialName>
#	<gn:alternateName xml:lang="ba">Лондон</gn:alternateName>
# </gn:Feature>

# Ouverture du fichier d'output final
open(XML,'>','geonames_output.xml') ;
binmode(XML, ":utf8") ;
print XML '<?xml version="1.0" encoding="UTF-8"?>'."\n" ;
print XML "<translit>\n" ;

# Variable pour vérifier si le nom a bien été trouvé
my $check = 0 ;

# Pour chaque lieu trouvé par Geonames
foreach my $place_name (@{$parser->{'gn:Feature'}})
{
	print "Lieu cherché :".$place_name->{'gn:name'}."\n" ;
	# Pour chaque nom officiel du lieu
	foreach my $off_name (@{$place_name->{'gn:officialName'}})
	{
		# Si le nom officiel français est identique à la requête
		if ($off_name->{'xml:lang'} eq 'fr' &&
			lc($off_name->{content}) eq $req)
		{
			# Impression dans le fichier d'output du nom français repéré
			print XML "\t<entite id=\"".$off_name->{content}."\">\n" ;
			# On change la valeur de la variable $check pour signaler qu'on a trouvé le lieu correspondant à la requête
			$check = 1 ;
			print $off_name->{content}." a été trouvé(e).\n" ;
			last ;
		}
	}
	# Si le lieu n'a pas été trouvé dans les noms officiels (qui sont facultatifs)
	if ($check == 0)
	{
		# Pour chaque nom alternatif du lieu
		foreach my $alt_name (@{$place_name->{'gn:alternateName'}})
		{
			# Si le nom officiel français est identique à la requête
			if ($alt_name->{'xml:lang'} eq 'fr' &&
				lc($alt_name->{content}) eq $req)
			{
				# Impression dans le fichier d'output du nom français repéré
				print XML "<entite id=\"".$alt_name->{content}."\">\n" ;
				# On change la valeur de la variable $check pour signaler qu'on a trouvé le lieu correspondant à la requête
				$check = 1 ;
				print $alt_name->{content}." a été trouvé(e).\n" ;
				last ;
			}
		}
	}
	# Si $check == 1, alors le lieu a été repéré
	if ($check == 1)
	{
		# On recommence la boucle sur chaque nom officiel
		foreach my $off_name2 (@{$place_name->{'gn:officialName'}})
		{
			# Si la langue du nom est différente du français (déjà indiqué dans le fichier XML)
			if ($off_name2->{'xml:lang'} ne 'fr')
			{
				# Impression de la langue et de la translitération
				print XML "\t\t<forme source=\"Geonames\" langue=\"".$off_name2->{'xml:lang'}."\">".$off_name2->{content}."</lang>\n" ;
			}
		}
		# On recommence la boucle sur chaque nom alternatif
		foreach my $alt_name2 (@{$place_name->{'gn:alternateName'}})
		{
			# Si la langue du nom est différente du français, déjà indiqué dans le fichier XML
			if ($alt_name2->{'xml:lang'} ne 'fr')
			{
				# Impression de la langue et de la translitération
				print XML "\t\t<forme source=\"Geonames\" langue =\"".$alt_name2->{'xml:lang'}."\">".$alt_name2->{content}."</lang>\n" ;
			}
		}
		print XML "\t</entite>\n";
		last ;
	}
}
if ($check == 0)
{
	print "L'entité n'a pas été trouvée. Veuillez recommencer ou mettre à jour Geonames.\n"
}

print XML "</translit>" ;
close XML ;