=begin

= rd2latex-lib.rb

Copyright (C) 2001  Shugo Maeda <shugo@ruby-lang.org>

This library is distributed under the terms of the Ruby license.
You can freely distribute/modify this library.

=end

require "rd/rdvisitor"
require "rd/version"

module RD
  class DescListItem
    class Term
      private

      def calculate_label
	ret = ""
	children.each do |i|
	  ret.concat(i.to_label)
	end
	":" + ret
      end
    end
  end

  class RD2LaTeXVisitor < RDVisitor
    include MethodParse
    include AutoLabel

    SYSTEM_NAME = "RDtool -- RD2LaTeXVisitor"
    SYSTEM_VERSION = "0.2"
    VERSION = Version.new_from_version_string(SYSTEM_NAME, SYSTEM_VERSION)

    def self.version
      VERSION
    end

    OUTPUT_SUFFIX = "tex"
    INCLUDE_SUFFIX = ["tex"]

    METACHAR = { 
      '#'  => '\#',
      "\\" => '\\verb$\\$',
      "%" => '\%',
      "$"  => '\$',
      '_'  => '\_',
      '&'  => '\&',
      '{'  => '\{',
      '}'  => '\}',
      # '-'  => '$-$',
      '<'  => '$<$',
      '>'  => '$>$',
      '|'  => '$|$',  # '
      '^'  => '$\\hat{ }$',
      '~'  => '$\\tilde{ }$'
    }
    METACHARSET = Regexp.new("[#{METACHAR.keys.join('').sub(/\\/, '\\\\\\\\')}]")

    attr_accessor :documentclass, :documentclass_option,
      :title, :author, :date, :preamble_file,
      :maketitle, :maketoc, :chapter_page, :clearpage_per_section

    def initialize
      @index = {}
      @documentclass = "jarticle"
      @documentclass_option = nil
      @title = nil
      @author = nil
      @date = nil
      @preamble_file = nil
      @maketitle = false
      @maketoc = false
      @chapter_page = false
      @clearpage_per_section = false
      super
    end

    def visit(tree)
      prepare_labels(tree, "label:")
      super(tree)
    end

    def apply_to_DocumentElement(element, content)
      if @documentclass_option
	option = "[#{@documentclass_option}]"
      else
	option = ""
      end
      str = %Q(\\documentclass#{option}{#{@documentclass}}\n)
      if @title
	str << %Q(\\title{#{@title}}\n)
      end
      if @author
	str << %Q(\\author{#{@author}}\n)
      end
      if @date
	str << %Q(\\date{#{@date}}\n)
      end
      if @preamble_file
	str << open(@preamble_file).read
      end
      str << "\\begin{document}\n"
      if @maketitle
	str << "\\maketitle\n"
      end
      if @maketoc
	str << "\\tableofcontents\n\\clearpage\n"
      end
      str << content.join
      str << "\n"
      str << %Q[\\end{document}\n]
      return str
    end

    def apply_to_Headline(element, title)
      anchor = get_anchor(element)
      if @documentclass =~ /article$/
	level = element.level
      else
	level = element.level - 1
      end
      if level == 0
	s = %Q[\\chapter{\\label{#{anchor}} #{title}}\n\n]
	if @chapter_page
	  s + %Q[\\setcounter{page}{1}\n\n]
	else
	  s
	end
      elsif level < 4
	s = %Q[\\#{"sub"*(level-1)}section{\\label{#{anchor}} #{title}}\n\n]
	if @clearpage_per_section
	  %Q[\\clearpage\n\n] + s
	else
	  s
	end
      else
	%Q[\\paragraph{\\label{#{anchor}} #{title}} \\\n\n]
      end
    end

    # RDVisitor#apply_to_Include 
    def apply_to_Include(element)
      fname = search_file(element.filename, element.tree.include_paths,
			  @include_suffix)
      if fname
	return File.readlines(fname).join("") + "\n"
      else
	return "\n"
      end
    end

    def apply_to_TextBlock(element, content)
      content.join + "\n"
    end

    def apply_to_Verbatim(element)
      content = []
      element.each_line do |i|
	content.push(i)
      end
      %Q[\\begin{verbatim}\n#{content.join}\\end{verbatim}\n]
    end

    def apply_to_ItemList(element, items)
      %Q[\\begin{itemize}\n#{items.join("\n")}\n\\end{itemize}\n]
    end

    def apply_to_EnumList(element, items)
      %Q[\\begin{enumerate}\n#{items.join("\n")}\n\\end{enumerate}\n]
    end

    def apply_to_DescList(element, items)
      %Q[\\begin{description}\n#{items.join("\n")}\n\\end{description}\n]
    end

    def apply_to_MethodList(element, items)
      %Q[\\begin{description}\n#{items.join("\n")}\n\\end{description}\n]
    end

    def apply_to_ItemListItem(element, content)
      content = content.join.sub(/\n*\z/, "")
      %Q[\\item #{content}]
    end

    def apply_to_EnumListItem(element, content)
      content = content.join.sub(/\n*\z/, "")
      %Q[\\item #{content}]
    end

    def apply_to_DescListItem(element, term, description)
      term = term.join.chomp
      #term.gsub!(/[{}]/, "\\\\\\&")
      #term.gsub!(/\[.*?\]/, "{\\&}")
      anchor = get_anchor(element.term)
      if description.empty?
	%Q(\\item[\\label{#{anchor}} #{term}] \\quad)
      else
	description = description.join.sub(/\n*\z/, "")
        %Q(\\item[\\label{#{anchor}} #{term}] \\quad \\\\\n) +
	  %Q[#{description}]
      end
    end

    def apply_to_MethodListItem(element, term, description)
      term = parse_method(term)  # maybe: term -> element.term
      anchor = get_anchor(element.term)
      if description.empty?
	%Q(\\item[\\label{#{anchor}} #{term}] \\quad)
      else
	description = description.join.sub(/\n*\z/, "")
        %Q(\\item[\\label{#{anchor}} #{term}] \\quad \\\\\n) +
	  %Q[#{description}]
      end
    end

    def parse_method(method)
      klass, kind, method, args = MethodParse.analize_method(method)
      
      if kind == :function
	klass = kind = nil
      else
	kind = MethodParse.kind2str(kind)
      end
      
      case method
      when "self"
	klass, kind, method, args = MethodParse.analize_method(args)
	"{\\tt #{klass}#{kind}self #{method}#{args}}"
      when "[]"
	args.strip!
	args.sub!(/^\((.*)\)$/, '\\1')
	"{\\tt #{klass}#{kind}[#{args}]}"
      when "[]="
	args.strip!
	args.sub!(/^\((.*)\)$/, '\\1')
	args, val = /^(.*),([^,]*)$/.match(args)[1,2]
	args.strip!
	val.strip!

	"{\\tt #{klass}#{kind}[#{args}] = #{val}}"
      else
	"{\\tt #{klass}#{kind}#{method}#{args}}"
      end
    end
    private :parse_method

    def apply_to_StringElement(element)
      apply_to_String(element.content)
    end

    def apply_to_Emphasis(element, content)
      %Q[{\\em #{content.join}}]
    end

    def apply_to_Code(element, content)
      c = element.content.collect { |c| c.content }.join
      %Q[\\texttt{#{meta_char_escape(c)}}]
    end

    def apply_to_Var(element, content)
      %Q[{\\tt #{content.join}}]
    end

    def apply_to_Keyboard(element, content)
      %Q[{\\sf #{content.join}}]
    end

    def apply_to_Index(element, content)
      tmp = []
      element.each do |i|
	tmp.push(i) if i.is_a?(String)
      end
      key = meta_char_escape(tmp.join)
      if @index.has_key?(key)
	# warning?
      else
	num = @index[key] = @index.size
	#%Q[<A NAME="index:#{num}">#{content.join("")}</A>]
      end
    end

    def apply_to_Reference(element, content)
      case element.label
      when Reference::URL
	apply_to_RefToURL(element, content)
      when Reference::RDLabel
	if element.label.filename
	  apply_to_RefToOtherFile(element, content)
	else
	  apply_to_RefToElement(element, content)
	end
      end
    end

    def apply_to_RefToElement(element, content)
      if anchor = refer(element)
	%Q[\\ref{#{anchor}}]
      else
	content.join
      end
    end

    def apply_to_RefToOtherFile(element, content)
      content.join
    end

    def apply_to_RefToURL(element, content)
      content.join
    end

    def apply_to_Footnote(element, content)
      %Q[\\footnote{#{content.join}}]
    end

    def apply_to_Verb(element)
      c = element.content
      %Q[\\texttt{#{meta_char_escape(c)}}]
    end

    def apply_to_String(element)
      meta_char_escape(element)
    end

    private

    def meta_char_escape(str)
      str.gsub(METACHARSET) {
	METACHAR[$&]
      }.gsub(/\[.*?\]/, "{\\&}")
    end
  end
end

$Visitor_Class = RD::RD2LaTeXVisitor
$RD2_Sub_OptionParser = "rd/rd2latex-opt"
