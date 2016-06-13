#!/usr/bin/perl

use strict;
use warnings;
use RDF::Query::Client;
use Term::ProgressBar 2.00;
use utf8;
binmode(STDOUT, ":utf8");
use JSON;
use Data::Dumper;

# Décompte du nombre de triplets
my $query = RDF::Query::Client->new('select count(*) as ?count where {?entite owl:sameAs ?nomInternational}');
my $iterator = $query->execute('http://fr.dbpedia.org/sparql');
my $tripletsMax = $iterator->next->{count}->as_string;
$tripletsMax =~ s/[^0-9]*([0-9]*)[^0-9]+.*/$1/g;
print "Nombre de triplets trouvés : $tripletsMax\n";


# Requêtes
my $offset = 0;
# my $cycle = 0;
my %translit;
my %languages;
my $progress = Term::ProgressBar->new($tripletsMax);
# EXC et EXCF servent pour l'instant à stocker les résultats non conformes au modèle prévu dans les résultats d'entités et de nom internationaux
open (EXC,">:encoding(utf8)","exceptions_nomInternational.txt");
open (EXCFR,">:encoding(utf8)","exceptions_entite.txt");
while ($offset < $tripletsMax) {
	$progress->update($offset);
# 	if ($cycle == 10) {
# 		sleep(1);
# 		$cycle = 0;
# 	}
	$query = RDF::Query::Client->new("select ?entite ?nomInternational where {?entite owl:sameAs ?nomInternational} LIMIT 1000 OFFSET $offset");
	$iterator = $query->execute('http://fr.dbpedia.org/sparql');
	
	# Stockage des résultats dans les différentes hash
	while (my $row = $iterator->next) {
		my $entiteURI = $row->{entite}->as_string;
		my $entite;
		if ($entiteURI =~ /http:\/\/fr.dbpedia.org\/resource\/(.+)>/) {
			$entite = $1;
		}
		else {
			print EXCFR "$entiteURI\tOFFSET = $offset\n";
			next;
		}
		
		my $nomInternationalURI = $row->{nomInternational}->as_string;
		my $langue;
		my $nomInternational;
		if ( $nomInternationalURI =~ /http:\/\/([^\/]+)\/resource\/(.+)>/ ) {
			$langue = $1;
			if ($langue eq "dbpedia.org") {
				$langue = "en";
			}
			else {
				$langue =~ s/\.dbpedia\.org//
			}
			$nomInternational = $2;
			$languages{$langue} = $offset;
			$translit{$entite}{$langue} = $nomInternational;
		}
		else {
			print EXC "$nomInternationalURI\tOFFSET = $offset\n";
		}
		#print "$entite\t$langue\t$nomInternational\n";
	}
# 	$cycle++;
	$offset = $offset+1000;
}
close EXC;
close EXCFR;
$progress->update($tripletsMax);

# Ecriture des résultats dans un fichier XML
open (TRANSLIT,">:encoding(utf8)","translit.xml");
print TRANSLIT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<translit>\n";
foreach my $entite (keys(\%translit)) {
	my $entitexml = $entite;
	$entitexml =~ s/</&lt;/g;
	$entitexml =~ s/>/&gt;/g;
	$entitexml =~ s/&/&amp;/g;
	$entitexml =~ s/"/&quot;/g;
	$entitexml =~ s/'/&apos;/g;
	print TRANSLIT "\t<entite id =\"$entitexml\">\n";
	
	foreach my $langue (keys($translit{$entite})) {
		my $forme = $translit{$entite}{$langue};
		$forme =~ s/</&lt;/g;
		$forme =~ s/>/&gt;/g;
		$forme =~ s/&/&amp;/g;
		$forme =~ s/"/&quot;/g;
		$forme =~ s/'/&apos;/g;
		print TRANSLIT "\t\t<forme source=\"DBpedia\" langue=\"$langue\">$forme</forme>\n";
	}
	
	print TRANSLIT "\t</entite>\n";
}
print TRANSLIT "</translit>";
close TRANSLIT;

# Ecritures des différentes langues trouvées dans un fichier txt
open (LANGUES,">:encoding(utf8)","langues.txt");
foreach my $langue (keys(\%languages)) {
	print LANGUES "$langue ===> Last found at offset ".$languages{$langue}."\n";
}
close LANGUES;