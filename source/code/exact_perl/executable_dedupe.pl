#!/usr/bin/env perl
use strict;
use warnings;

use Config; 
use File::Spec; 
use Cwd;

# Alorithm:
#   1. Find all paths in PATH
#   2. For each path
#     2a. if it is absolute, get the realpath
#     2b. else, normalize it (KEEP relative!)
#   3. If the realpath hasn't been seen before, add it to the list
#   4. join the list with ":"

# Note: this tranlates empty paths to "."
my @PATH = File::Spec->path(); # 1.

my %seen;
my @res;
for my $path (@PATH) { # 2.
  my $realpath =  (File::Spec->file_name_is_absolute($path) && -d $path)
      ? Cwd::realpath($path) # 2a.
      : File::Spec->canonpath($path); # 2b.
  # 3.
  if ($seen{$realpath}++) { next; }
  push @res, $realpath;
}

print join($Config{path_sep}, @res); # 4.
