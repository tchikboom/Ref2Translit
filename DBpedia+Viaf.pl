#!/usr/bin/perl

use strict;
#use warnings;
use RDF::Query::Client;
use Term::ProgressBar 2.00;
use utf8;
binmode(STDOUT, ":utf8");
use JSON;
#use Data::Dumper;
use XML::LibXML;

my $tripletsMax = decompteTriplet();
print "Nombre de triplets trouvés : $tripletsMax\n";
my %viaf;
my %idref;
#open (IDREF,'>:encoding(utf8)','idref.txt');
my $translit = requetes($tripletsMax);
#close IDREF;
ecritureXML($translit);


#================= Décompte du nombre de triplets =================
sub decompteTriplet {
	my $query = RDF::Query::Client->new('select count(*) as ?count where {?entite owl:sameAs ?nomInternational.}');
	#my $query = RDF::Query::Client->new('select count(*) as ?count where {?entite owl:sameAs ?nomInternational. ?entite owl:sameAs <http://www.viaf.org/viaf/97786459>.}');
	my $iterator = $query->execute('http://fr.dbpedia.org/sparql');
	my $triplets = $iterator->next->{count}->as_string;
	$triplets =~ s/[^0-9]*([0-9]*)[^0-9]+.*/$1/g;
	return $triplets;
}

#================= Requêtes =================
sub requetes {
	my ($offsetmax) = @_;
	my $offset = 0;
	my %translit;
	my $progress = Term::ProgressBar->new($offsetmax);
	my $query;
	my $iterator;
	while ($offset < $offsetmax) {
		$progress->update($offset);
		$query = RDF::Query::Client->new("select ?entite ?nomInternational where {?entite owl:sameAs ?nomInternational.} LIMIT 1000 OFFSET $offset");
		#$query = RDF::Query::Client->new("select ?entite ?nomInternational where {?entite owl:sameAs ?nomInternational. ?entite owl:sameAs <http://www.viaf.org/viaf/97786459>.} LIMIT 1000 OFFSET $offset");
		$iterator = $query->execute('http://fr.dbpedia.org/sparql');
		
		# Stockage des résultats dans les différentes hash
		my $entiteURI;
		my $nomInternationalURI;
		my $langue;
		my $nomInternational;
		while (my $row = $iterator->next) {
			
			$entiteURI = $row->{entite}->as_string;
			$nomInternationalURI = $row->{nomInternational}->as_string;
			
			if ($entiteURI =~ /<(http:\/\/fr.dbpedia.org\/resource\/.+)>/) {
				$entiteURI = $1;
			}
			else {
				next;
			}
			
			unless (exists $translit{$entiteURI}{"fr"}) {
				if ($entiteURI =~ /http:\/\/fr.dbpedia.org\/resource\/(.+)/) {
					$nomInternational = $1;
				}
				else {
					next;
				}
				$nomInternational = nettoyageNomInternational($nomInternational);
				$translit{$entiteURI}{"fr"} = $nomInternational;
			}
			
			if ( $nomInternationalURI =~ /http:\/\/([^\/]+)\/resource\/(.+)>/ ) {
				$langue = $1;
				if ($langue eq 'dbpedia.org') {
					$langue = 'en';
				}
				else {
					$langue =~ s/\.dbpedia\.org//
				}
				if ($langue eq 'commons') {
					next;
				}
				elsif ($langue ne 'fr') {
					$nomInternational = $2;
				}
				else {
					next
				}
				$nomInternational = nettoyageNomInternational($nomInternational);
			}
			elsif ( $nomInternationalURI =~ /<http:\/\/www\.viaf\.org\/viaf\/([0-9]+)>/ ) {
				my $viafid = $1;
				unless (exists $translit{$entiteURI}{'viaf'}) {
					viafExtractor($viafid,\%translit,$entiteURI);
				}
				next;
			}
			elsif ( $nomInternationalURI =~ /<http:\/\/www\.idref\.fr\/([^\/]+)\/id>/ ) {
				#my $idrefid = $1;
				#$idref{$idrefid} = $entiteURI;
				next;
			}
			else {
				next;
			}
			
			$translit{$entiteURI}{$langue} = $nomInternational;
		}
		$offset = $offset+1000;
	}
	$progress->update($offsetmax);
	
	#foreach my $idrefid (keys(\%idref)) {
	#	print IDREF "$idrefid\t".$idref{$idrefid}."\n";
	#}
	
	return \%translit;
}

#================= Nettoyage des noms internationaux =================
sub nettoyageNomInternational {
	my ($nomInternational) = @_;
	$nomInternational =~ s/_/ /g;
	if ($nomInternational =~ /^[^:]+[^ :]:([^ :].*)$/) {
		$nomInternational = $1;
	}
	if ($nomInternational =~ /^(.*[^ ]) ?\([^)]+\)$/) {
		$nomInternational = $1;
	}
	return $nomInternational;
}

#================= Ecriture des résultats dans un fichier XML =================
sub ecritureXML {
	my ($translit) = @_;
	open (TRANSLIT,'>:encoding(utf8)','translit.xml');
	print TRANSLIT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rdf:RDF xmlns:skos=\"http://www.w3.org/2004/02/skos/core#\"\n         xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n";
	foreach my $entite (keys(\%{$translit})) {
		unless ( keys(${$translit}{$entite}) == 1 ) {
			my $entitexml = $entite;
			$entitexml =~ s/</&lt;/g;
			$entitexml =~ s/>/&gt;/g;
			$entitexml =~ s/&/&amp;/g;
			$entitexml =~ s/"/&quot;/g;
			$entitexml =~ s/'/&apos;/g;
			print TRANSLIT "\t<skos:Concept rdf:about=\"$entitexml\">\n";
			
			foreach my $langue (keys(${$translit}{$entite})) {
			
				if ($langue eq 'viaf') {
					foreach my $forme  (@{${$translit}{$entite}{$langue}}) {
						print TRANSLIT "\t\t<skos:altLabel>$forme</skos:altLabel>\n";
					}
				}
				else {
					my $forme = ${$translit}{$entite}{$langue};
					$forme =~ s/</&lt;/g;
					$forme =~ s/>/&gt;/g;
					$forme =~ s/&/&amp;/g;
					$forme =~ s/"/&quot;/g;
					$forme =~ s/'/&apos;/g;
					chomp($forme);
					print TRANSLIT "\t\t<skos:prefLabel xml:lang=\"$langue\">$forme</skos:prefLabel>\n";
				}
			}
			
			print TRANSLIT "\t</skos:Concept>\n";
		}
	}
	print TRANSLIT "</rdf:RDF>";
	close TRANSLIT;
}

#================= Extraction à partir de VIAF =================
sub viafExtractor {
	my ($viafid,$refTranslit,$entiteURI) = @_;
	
	my $xml;
	eval{
		$xml = XML::LibXML->load_xml(location => 'http://viaf.org/viaf/'.$viafid.'/');
	};
	
	
	unless ($@) {
		$xml = XML::LibXML::XPathContext->new($xml->documentElement);
		$xml->registerNs('ns2', 'http://viaf.org/viaf/terms#');
		#Boucle sur les différentes formes
		for my $node ($xml->findnodes('/ns2:VIAFCluster/ns2:mainHeadings/ns2:data/ns2:text')) {
			my $forme = $node->findvalue('.');
			push(@{${$refTranslit}{$entiteURI}{'viaf'}},$forme);
		}
        }
}