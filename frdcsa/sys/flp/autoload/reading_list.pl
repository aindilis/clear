%% see that file of important books.  implement their purposes as well.

desires(andrewDougherty,done(read(andrewDougherty,fileFn(File)))) :-
	listFullFilePathsOfFilesInDirectory('/var/lib/myfrdcsa/collections/Michael-Iltis/',Files),
	member(File,Files).

readingList([asherFromAIChannelThesis,stealingTheNetworkHowToOwnAContinent_TheBook,prologProgrammingForArtificialIntelligence_TheBook]).

desires(andrewDougherty,done(read(andrewDougherty,Text))) :-
	readingList(andrewDougherty,ReadingList),
	member(Text,Readinglist).

readingList(andrewDougherty,[asherFromAIChannelThesis,stealingTheNetworkHowToOwnAContinent_TheBook,prologProgrammingForArtificialIntelligence_TheBook,websiteFn('http://www.swi-prolog.org/')]).

readingList(meredithMcGhan,[computationalAutism_TheBook]).
