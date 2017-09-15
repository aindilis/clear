#!/usr/bin/perl -w

# while there are probably much better  ways to do this, we don't know
# them and  we need  a quick solution,  so we'll  do this by  hand for
# starters.

# the goal is to take a given document and generate a content summary.
# A simple  example would  be to classify  it according to  library of
# congress classification (LCC).  but  that is not very descriptive of
# a wide-ranging class of information not contained.

# Therefore what we need is  some kind of enormous extracted hierarchy
# or graph of information.

# we said  we'd use PICForm,  but I don't  know how to do  that.  I'll
# look at those writings in a second.

# In  the  mean time,  how  might  we  generate this  graph?   Concept
# extraction, etc.

# First of  all, the  graph should be  extracted in relation  to other
# documents as  well.  So, a first  pass over all  documents should be
# done.

# From that, you  have a large model of all the  areas.  I suppose you
# can detect when noun phrases sound like subject areas.

# Create  some   hierarchical  subject   model,  and  then   go  about
# intersecting that with each document.
