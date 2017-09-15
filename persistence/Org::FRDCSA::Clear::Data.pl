:- dynamic ':-'/2, md/2, r/3, metaData/2, read/3.

:- discontiguous arg1Isa/2, arg2Isa/2, arg3Isa/2.

:- consult('/var/lib/myfrdcsa/codebases/minor/free-life-planner/lib/util/util.pl').

%% expandShortToLongPredicateNames :-
%% 	hasExpanded(List),
%% 	member([ShortPredicateName,Arity,LongPredicateName],List),
%% 	length(ArgList,Arity),
%% 	ShortPredicate =.. [ShortPredicateName|ArgList],
%% 	LongPredicate =.. [LongPredicateName|ArgList],
%% 	assert(LongPredicate :- ShortPredicate).

hasExpanded([
	     [md,2,metaData],
	     [d,1,document],
	     [fi,1,fileInstance],
	     [f,1,file],
	     [fn,1,fileName],
	     [fns,1,fileNameString],
	     [t,1,title],
	     [ts,1,titleString],
	     [dts,1,dateTimeStamp],
	     [a,1,author],
	     [as,1,authorString],
	     %% [tv,1,?],
	     [r,1,read],
	     [s,1,sentence],
	     [to,1,timeOffset],
 	     [p,1,pageNo]
	     ]).

arg1Isa(metaData/2,object).
arg2Isa(metaData/2,metaDataProperty).
arg1Isa(document/1,idFn(document)).
arg1Isa(fileInstance/1,file).
arg1Isa(file/1,idFn(file)).
arg1Isa(fileName/1,idFn(fileName)).
arg1Isa(fileNameString/1,stringFn(fileName)).
arg1Isa(timeStamp/1,dateTime).
arg1Isa(title/1,idFn(title)).
arg1Isa(titleString/1,stringFn(title)).
arg1Isa(author/1,idFn(author)).
arg1Isa(authorString/1,stringFn(author)).
arg1Isa(read/3,document).
arg2Isa(read/3,sentence).
arg3Isa(read/3,timeOffset).
arg1Isa(sentence/1,idFn(sentence)).
arg1Isa(timeOffset/1,duration).

%% are([fi,],metaDataProperty).

%% :- consult('Org::FRDCSA::Clear::DocumentMetadata').
%% %% Document METADATA

md(d(1453),fi(f(152))).
md(f(152),fn(13513)).
md(fn(13513),fns('/home/andrewdo/exegesis.pdf')).
md(f(152),dts([2017-5-14,12:0:12])).
md(f(152),t(152)).
md(t(152),ts('Exegesis')).
md(f(152),a(12)).
md(a(12),as('Philip K. Dick')).
md(f(152),crc('315135')).
md(f(152),md5('adkfdsfj')).
%% ??? md(d(1453),tv(f(353))).

%% :- consult('Org::FRDCSA::Clear::DocumentReadingData').
%% DOCUMENT READING DATA

%% FIXME: what was the d(1) supposed to refer to? r(d(1453),s(12),d(1),t(1.01)).

r(d(1453),s(12),to(1.01)).
r(d(1453),s(13),to(2.0)).
r(d(1453),p(15),to(33523)).

%% integrate this with KBFS and the book metadata system.  also
%% integrate with the system for ocr, etc.

%% FIXME: figure out what other systems to integrate here.  probably
%% torrent system, etc.  Academician, Digilib, NLU-MF, etc.

%% recursively convert

%% term_contains_subterm_nonvar(SubTerm, Term) :-
%%         not(compound(Term)),
%%         nonvar(Term),
%%         SubTerm=Term.
%% term_contains_subterm_nonvar(SubTerm, Term) :-
%%         compound(Term),
%%         nonvar(Term),
%%         compound_name_arguments(Term, SubTerm, _).
%% term_contains_subterm_nonvar(SubTerm, Term) :-
%%         compound(Term),
%%         nonvar(Term),
%%         arg(_, Term, SubSubTerm),
%%         term_contains_subterm_nonvar(SubTerm, SubSubTerm).

expandFact(Pre,Post) :-
        %% view([pre,Pre]),
        (   is_list(Pre) ->
	    (	findall(Item,(member(SubPre,Pre),expandFact(SubPre,Item)),Post)) ;
	    (	not(nonvar(Pre)) ->
		(   Post = Pre ); 
		(   atomic(Pre) ->
		    (	Post = Pre) ;
		    Pre =.. [ShortPredicateName|Args] ->
		    (	
			findall(Item,(member(SubArgs,Args),expandFact(SubArgs,Item)),Items),
			relatePredicateNames(ShortPredicateName,PredicateName),
			%% view([predicateName,PredicateName]),
			Post =.. [PredicateName|Items]
		    ) ; true))).

relatePredicateNames(ShortPredicateName,PredicateName) :-
	hasExpanded(List),
	member([ShortPredicateName,Arity,PredicateName],List).

contractFact(Pre,Post) :-
        %% view([pre,Pre]),
        (   is_list(Pre) ->
	    (	findall(Item,(member(SubPre,Pre),contractFact(SubPre,Item)),Post)) ;
	    (	not(nonvar(Pre)) ->
		(   Post = Pre ); 
		(   atomic(Pre) ->
		    (	Post = Pre) ;
		    Pre =.. [PredicateName|Args] ->
		    (	
			findall(Item,(member(SubArgs,Args),contractFact(SubArgs,Item)),Items),
			relatePredicateNames(ShortPredicateName,PredicateName),
			%% view([predicateName,PredicateName]),
			Post =.. [ShortPredicateName|Items]
		    ) ; true))).


expandFacts(NewFacts) :-
	findall(NewFact,(((md(X,Y),Fact = md(X,Y)) ; (r(X,Y,Z),Fact = r(X,Y,Z))),expandFact(Fact,NewFact)),NewFacts).

contractFacts(NewFacts) :-
	findall(NewFact,(((metaData(X,Y),Fact = metaData(X,Y)) ; (read(X,Y,Z),Fact = read(X,Y,Z))),contractFact(Fact,NewFact)),NewFacts).

tmpView(Item) :-
	write_term(Item,[quoted(true)]).

assertExpanded :-
	expandFacts(NewFacts),
	forall(member(NewFact,NewFacts),(view(NewFact),assert(NewFact))).

test :-
	assertExpanded,
	contractFacts(NewFacts),
	view([NewFacts]).

createNew(PredicateName,NewPredicate) :-
	Predicate =.. [PredicateName,_],
	findall(ID,(Predicate,Predicate =.. [PredicateName,ID]),IDs),
	max(IDs,MaxID),
	NewID is MaxID + 1,
	NewPredicate =.. [PredicateName,NewID].

%% d(1453).
%% f(152).
%% fn(13513).
%% t(152))
%% a(12).

%% ts([2017-5-14,12:0:12]).

processFileNameWithClear(FileName) :-
	md(fn(FNID),fns(FileName)),
	md(f(FID),fn(FNID)),
	findall(Datum1,(md(f(FID),X),Datum1 = md(f(FID),X)),Data1),
	findall(Datum3,(
			member(md(X,Y),Data1),
			findall(Datum2,md(Y,Datum2),Data2),
			member(Datum3,Data2)
		       ),Data3),
	view([Data1,Data3]).

markSentenceRead(temp) :-
	true.
