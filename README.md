# clear
A mature ebook/document reading program including text to speech and other useful features

http://frdcsa.org/frdcsa/internal/clear

<system>
  <title>CLEAR</title>
  <acronym-expansion>
    Computer LEarning ARchitecture
  </acronym-expansion>
  <short-description>
  </short-description>
  <slogan>
    Are we CLEAR?  
  </slogan>
  <medium-description>
    Intelligent  Tutoring  System  for distance  learning.   Maintains
    reading lists for  content areas, automatically determines reading
    list dependencies.   Uses TTS  to read documents.   Records user's
    attention  during  reading.  Generates  tests  from documents  for
    placement or  assessment.  Eventually, expect  to integrate webcam
    based eye-tracking system, so that records of what has been read
  </medium-description>
  <long-description>
    <p>
      CLEAR is a great way to have books, manuals, websites, etc, read
      to  you, allowing  you to  pause, quit,  resume, and  filter out
      nonsense.  Clear uses the Festival text-to-speech system and ccp
      to  do this.   It is  very useful  for studying.   For instance,
      while browsing a researchers website in w3m-el, you can select a
      region  over   all  of   their  publications  and   execute  M-x
      clear-queue-all-links  or  "\C-c\C-mc"  to  queue all  of  their
      papers.  A  message containing a  command to queue the  links is
      then sent from Emacs-Unilang-Agent to UniLang, which sends it to
      CLEAR.   The queued links  are stored  to the  current readlist.
      Whenever  you have  a  chance  then, you  tell  CLEAR to  resume
      reading and  it reads you books.   It sorts the  reading list by
      topical dependency.
    </p>
    <p>
      The  objective  is to  model  the  user's  reading flux  at  the
      sentence  level.   Conceptual understand  may  then be  modelled
      through analysis of the sentences.   A lot of data on the entire
      process is  recorded.  The purpose  is so that the  computer has
      another modality, in addition to things like expected background
      knowledge, apparent knowledge, to model which axioms the user is
      familiar with. (Eventually the Textbook Knowledge Formation tool
      chain we  are assembling with the Chess  Analysis Knowledge Base
      project will be used to model fields axiomatically as opposed to
      the  document level  granularity currently  used by  CLEAR.)  By
      modelling the  reading flux, a  much better mental model  can be
      created   and  the   system  can   behave   contingently.   This
      information is critical to many tasks, such as:
    </p>
    <p>
      <ul>
	<li>Assessing the user's background knowledge.</li>
	<li>Verifying familiarity with some tradecraft.</li>
      </ul>
    </p>
    <p>
      The motivation for CLEAR is inspired in part by the following
      information from the JAVELIN project: http://www.lti.cs.cmu.edu/Research/JAVELIN/
    </p>
    <em>
    <p>
      Utility-based Information Fusion. Any item of information I can
      be assigned a value representing its utility to analyst A with
      respect to task context T and question Q. The utility value can
      be used to rank the possible answers in a manner inspired by
      Maximal Marginal Relevance:
    </p>
    <p>
      U = Argmaxk[F(Rel(I,Q,T),Nov(I,T,A),Ver(S,Sup(I,S)),Div(S),Cmp(I,A)),Cst(I,A)]
    </p>
    <p>
      Essentially all information items (facts, links, inferred
      relations, etc.) in consideration for fusion into an answer may
      be ranked in utility to the analyst as a function of:
    </p>
    <p>
      <ul>
	<li>Rel: relevance to the requested information</li>
	<li>Nov: novelty (likelihood that the analyst does not already know it)</li>
	<li>Ver: veracity (of source S) and support for conclusion I within S</li>
	<li>Div: source diversity (analyst may want contrasting or reinforcing views)</li>
	<li>Cmp: comprehensibility of information by the analyst (one can assume a uniform distribution until the system learns otherwise from analyst feedback)</li>
	<li>Cst: expected cost (e.g. time) for the analyst to assimilate the information.</li>
      </ul>
    </p>
    </em>
    <p>
      The way CLEAR does this is by monitoring the users readers, and
      deriving belief models of the user's state (such as awareness,
      eye-position, whether they were listening (in the case of
      auditory media) etc), as these reader applications were running.
      Currently only reading is implemented, as I don't have a
      suitable eye-tracker.
    </p>
    <p>
      In addition to reading, currently CLEAR can quiz the
      user, as in this example:
      <pre>
/var/lib/myfrdcsa/codebases/internal/clear $ clear -q lists/camo.rl 
Readlist is lists/camo.rl
Initializing TTS engine...
festival: no process killed
server    Tue Dec 28 20:10:06 2004 : Festival server started on port 1314
Reviewing library/us-army-field-manuals/extracted/20-3/US ARMY FM 20-3 Camoflage Concealment And Decoys/ch4.PDF...
client(1) Tue Dec 28 20:10:08 2004 : accepted from pc-sonicparts

Question 0
Make optimum use of concealed routes, hollows, gullies, and other terrain
features that are dead-space areas to enemy observation and _____
positions.
% fighting
Incorrect! (firing)

Question 1
Although an enemy's use of radar and _____ aerial recon hinders operations
at night, darkness remains a significant concealment tool.
% visual
Incorrect! (ir)

Question 2
When natural _____ and concealment are unavailable or impractical, the
coordinated employment of smoke, suppressive fires, speed, and natural
limited-visibility conditions minimize exposure and avoid enemy fire sacks.
% cover
Correct! (cover)

Question 3
Designate concealed _____ for movement into and out of an area.
% routes
Correct! (routes)

Question 4
A trade-off, however, usually exists in _____ of a slower rate of movement
when using these types of routes. 4-18.
% this
Incorrect! (terms)
      </pre>
      One can see how Question 4 is not as useful as the others, but
      overall, I find the system to be very effective in liu of a real
      system.  If the shoe fits...
    </p>
    <p>
      This system used to be called: Correctly Learning An
      Individual's Reasoning Visually Or Yielded Assuming Normal
      Cognitive Execution (CLAIRVOYANCE), but this is just sort of
      inaccurate.  CLEAR is much, more, well, clear ;)
    </p>
    <p>
      CLEAR  is primarily  useful for  reading  documentation, papers,
      books, websites, digital library content, and other sources that
      are of  practical use to  the project, so  that we can  get much
      more  done,  especially while  resting  or  moving.  A  critical
      feature  is  the ability  to  read  documentation for  installed
      packages, because mastering newly installed software is critical
      to  the  FRDCSA mission  goal.   It  also  does very  well  with
      important  documents, like the  above survival  and preparedness
      information (as the recent  tsunami confirms).  Lastly, and most
      important, it allows us to  implement a system of instruction so
      that we can help to  train project members in various capacities
      and verify their progress, without being burdensome at all - but
      rather  entertaining.   This can  be  combined  with CRITIC  for
      collaborative filtering  based ratings  to enhance the  value of
      the information.  CLEAR in conjunction with DigiLib is also used
      by job-search to  ensure familiarity with position requirements.
      CLEAR uses functionality from CoAuthor to compose custom reading
      specific to users' tested proficiency and known reading history.
    </p>
  </long-description>
  <depends>
    ccp, festival, libclass-methodmaker-perl, w3m, libchm-bin
  </depends>
  <misc>

  </misc>
</system>
