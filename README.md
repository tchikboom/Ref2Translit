# Ref2Translit
Ensemble de scripts qui permettent d'extraire le contenu de différents référentiels pour obtenir les translittérations de différents termes dans un fichier XML au format SKOS.

## Synopsis

```perl NOM_DU_SCRIPT.pl```

## Pré-requis

Pour le bon fonctionnement des scripts, il faut installer les modules suivants, tous disponibles sur CPAN :

[Furl](http://search.cpan.org/~syohex/Furl-3.09/lib/Furl.pm)

[JSON::XS](http://search.cpan.org/~mlehmann/JSON-XS-3.02/XS.pm)

[JSON](http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm)

[RDF::Query::Client](http://search.cpan.org/~tobyink/RDF-Query-Client-0.114/lib/RDF/Query/Client.pm)

[XML::LibXML](http://search.cpan.org/dist/XML-LibXML/LibXML.pod)

[Term::ProgressBar](http://search.cpan.org/~szabgab/Term-ProgressBar-2.17/lib/Term/ProgressBar.pm)

##### Rappel du fonctionnement de l'installation de modules via CPAN :

```sudo CPAN```

```install Nom::Du::Module```

## Référentiels utilisés

DBpedia : Tout type d'entités, référentiel de Wikipédia
VIAF : Références bibliothécaires 
Geonames : Noms de lieux
The Movie Database : Noms de films
