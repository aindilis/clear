(fix things that are broken since I added the multiple books simultaneously
 (the clear queue from unilang)
 (the pause button using headset)
 (the load of the books)
 (switching to the active tab at startup)
 (goto etc)
 (the layout)
 (mark the active tab with a green activate button or something)
 (the ability to start/load a new readlist from the menu, or from unilang)
 (the ability to switch between lists using the headset)
 (pause work correctly)
 (ability to save state and load state of having multiple documents at different locations)
 (integration with Emacs)
 (improved handling of pdf text files)
 )


(apt-cache search festival)

(So there are a few different things that need to be done here.)

(first we need to fix it so that with parsing chm files, you don't have to supply the -f 'HTML document text' argument to get it to work)
(secondly we need to have it so that when you run it on a chm, it records the readinglist for that CHM, and saves it, and doesn't rm -rf /tmp/chm, but retrieves it from a particular stored location (probably somewhere in digilib?))
(thirdly, we need the display to work correctly, namely, when on a readinglist it jumps to the next item, it displays that item correctly, not the first readinglist item)
(fourthly it would be nice to fix that bug that has the first
 line highlighted perpetually)






(On my system, there is about a 2 second delay before aplay
finishes playing a sound.

 see http://lists.freedesktop.org/archives/pulseaudio-bugs/2010-October/004185.html

 http://comments.gmane.org/gmane.comp.audio.pulseaudio.general/14452

 This seems to be due to a complex issue with terminating the sound.

 The only solution I can think of is to implement a system for
 playing the next file before the return of the aplay script, so
 to stagger the aplay calls.

 You cannot kill the existing process any faster than letting it
 finish, but you can start the next one before the other one has
 returned.

 This means abandoning the festival server in favor of one time
 calls, and then knowing how long to wait before playing the next
 one, and so forth.
)




(Have it show text that has already been read according the color
 of how recently it was read..., as opposed to text that has
 never been read)

(Have it able to search the book repository)

(have the ability to select a piece of text and run different
 text to knowledge things on it, like build-isa-ontology.pl, etc.)

(related systems
 (academician - can search with it, process publications)
 (agent - formalization of what the reader knows/believes, etc)
 (android - a clear client for the phone)
 (bookmark-clustering - additional sources of information)

 (broker-buy-sell-system - ebook buy and sell perhaps?)

 (ccpp - converting between formats...)

 (?chap - for reading chess knowledge)

 (coauthor-interactive-natural-language-generator - )

 (corpus-browser - provide these texts as input to workhorse style processing)

 (finally fix workhorse)

 


 (documentation-central - )
 )

(centralize the totext functions that we see everywhere, we have
 the perllib::converter and PerlLib::ToText, etc)

