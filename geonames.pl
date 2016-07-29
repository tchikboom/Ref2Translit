#!/usr/bin/perl

use strict ;
use warnings ;

use utf8 ;
use Term::ProgressBar ;
use LWP::Simple ;
use Archive::Extract ;

binmode(STDIN, ":utf8") ;
binmode(STDOUT, ":utf8") ;

# Téléchargement du dump des noms alternatifs de Geonames
print "Téléchargement du dump des noms alternatifs de Geonames...\n" ;
my $url = "http://download.geonames.org/export/dump/alternateNames.zip" ;
my $zipname = "alternatenames.zip" ;
getstore($url, $zipname) ;
print "Téléchargement terminé.\n" ;
# Dézippage du fichier téléchargé
print "Extraction du fichier...\n" ;
my $unzip = Archive::Extract->new(archive => $zipname);
$unzip -> extract ;
print "Fichier extrait.\n" ;

# Lecture du fichier dézippé
open(my $file_cpt, '<', 'alternateNames.txt')
or die ("Le fichier alternateNames.txt n'a pas pu être ouvert.\n") ;

# On trouve le nombre de lignes du fichier pour la barre de chargement
my $nblignes = 0 ;
$nblignes += tr/\n/\n/ while sysread($file_cpt, $_, 2 ** 16) ;
close $file_cpt ;

# Réouverture du fichier alternateNames.txt, just because
open(my $file, '<', 'alternateNames.txt')
or die ("Le fichier alternateNames.txt n'a pas pu être ouvert.\n") ;

# Structure de données où seront enregistrés chaque translittération
my %results = () ;

# Création d'une barre de progression
print "Parsing du fichier...\n" ;
my $start = time() ;
my $progress_parse = Term::ProgressBar->new($nblignes) ;
my $cpt = 0 ;
my $cpt_true = 0;

while (my $ligne = <$file>)
{
	chomp($ligne) ;
	my $id = $ligne ;
	my $lang = $ligne ;
	my $name = $ligne ;

	$lang =~ s/[0-9]+\t[0-9]+\t([a-z]*)\t.+/$1/ ;
	# Nettoyage des translittérations non pertinentes
	if ($lang eq '' ||
		$lang eq 'link' ||
		$lang eq 'post' ||
		$lang eq 'iata' ||
		$lang eq 'icao' ||
		$lang eq 'new')
	{
		$progress_parse->update($cpt) ;
		$cpt++ ;
		next ;
	}
	$id =~ s/[0-9]+\t([0-9]+)\t[a-z]*\t.+/$1/ ;
	$name =~ s/[0-9]+\t[0-9]+\t[a-z]*\t(.+)\t+/$1/ ;
	$name =~ s/\t+// ;
	# Stocke les résultats dans un hash (entités) de hashs (langues) de listes (translittérations)
	push @{$results{$id}{$lang}}, $name ;
	$progress_parse->update($cpt) ;
	$cpt++ ;
	$cpt_true++ ;
}
$progress_parse->update($cpt) ;

# Création d'une table nettoyée
my %clean = () ;
my $languniq = 0 ;
my $transuniq = 0 ;

foreach my $entite (keys %results)
{
	if (scalar keys %{$results{$entite}} < 2)
	{
		$languniq = 1 ;
	}
	foreach my $langue (keys %{$results{$entite}})
	{
		if (scalar @{$results{$entite}{$langue}} < 2)
		{
			$transuniq = 1 ;
		}
		if ($languniq == 1 && $transuniq == 1)
		{
			next ;
			$transuniq = 0 ;
		}
		else
		{
			foreach my $translit (@{$results{$entite}{$langue}})
			{
				push @{$clean{$entite}{$langue}}, $translit ;
				$transuniq = 0 ;
			}
		}
	}
	$languniq = 0 ;
}

# Ouverture du fichier d'output
open (XML, '>', 'geonames_output.xml')
or die ("geonames_output.xml n'a pas pu être ouvert.\n") ;
print XML '<?xml version="1.0" encoding="UTF-8"?>'."\n" ;
print XML '<rdf:RDF xmlns:skos="http://www.w3.org/2004/02/skos/core#"
         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'."\n" ;

print "\nImpression des résultats...\n" ;
my $progress_write = Term::ProgressBar->new($cpt_true) ;
my $cpt2 = 0 ;

my %verif = () ;
# Pour chaque entité
foreach my $entite_clean (sort keys %clean)
{
	print XML "\t<skos:Concept rdf:about=\"".$entite_clean."\">\n" ;
	# Pour chaque langue de l'entités
	foreach my $langue_clean (sort keys %{$clean{$entite_clean}})
	{
		# Pour chaque translittération dans chaque langue de l'entité
		foreach my $translit_clean (@{$clean{$entite_clean}{$langue_clean}})
		{
			if (exists $verif{$langue_clean})
			{
				print XML "\t\t<skos:altLabel xml:lang=\"".$langue_clean."\">".$translit_clean."</skos:altLabel>\n" ;
				$progress_write->update($cpt2) ;
				$cpt2++ ;
			}
			else
			{
				$verif{$langue_clean} = 1 ;
				print XML "\t\t<skos:prefLabel xml:lang=\"".$langue_clean."\">".$translit_clean."</skos:prefLabel>\n" ;
				$progress_write->update($cpt2) ;
				$cpt2++ ;
			}
		}
	}
	print XML "\t</skos:Concept>\n" ;
	%verif = () ;
}
print XML "</rdf:RDF>\n" ;
close XML ;
$progress_write->update($cpt2) ;

my $end = time() ;
my $elapsed = $end-$start ;
my $minutes = $elapsed / 60 ;

print "\nTemps écoulé : ".$minutes." minutes.\n" ;
