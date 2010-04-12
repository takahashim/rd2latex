=begin

= rd2html-opt.rb

Copyright (C) 2001  Shugo Maeda <shugo@ruby-lang.org>

This library is distributed under the terms of the Ruby license.
You can freely distribute/modify this library.

=end

require "optparse"

q = ARGV.options

q.on_tail("rd2latex-lib options:")
  
q.on_tail("--documentclass=CLASS",
	  String,
	  "\\documentclass") do |i|
  $Visitor.documentclass = i
end
  
q.on_tail("--documentclass-option=OPT",
	  String,
	  "option for \\documentclass") do |i|
  $Visitor.documentclass_option = i
end
  
q.on_tail("--title=TITLE",
	  String,
	  "\\title") do |i|
  $Visitor.title = i
end
  
q.on_tail("--author=AUTHOR",
	  String,
	  "\\author") do |i|
  $Visitor.author = i
end
  
q.on_tail("--date=DATE",
	  String,
	  "\\date") do |i|
  $Visitor.date = i
end
  
q.on_tail("--preamble-file=FILE",
	  String,
	  "file to be included in preamble") do |i|
  $Visitor.preamble_file = i
end

q.on_tail("--maketitle",
	  "make title") do
  $Visitor.maketitle = true
end

q.on_tail("--maketoc",
	  "make table of contents") do
  $Visitor.maketoc = true
end

q.on_tail("--chapter-page",
	  "reset page number for every chapter") do
  $Visitor.chapter_page = true
end

q.on_tail("--clearpage-per-section",
	  "clearpage per section") do
  $Visitor.clearpage_per_section = true
end
