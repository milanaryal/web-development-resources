#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"

files = ARGV.empty? ? Dir.glob("**/*.md") : ARGV
errors = []

def slug(text)
  plain = text.gsub(/!?(\[([^\]]+)\])\([^)]*\)/, "\\2")
  plain.downcase.gsub(/<[^>]+>/, "").gsub(/[^\p{Alnum}\s_-]/, "")
       .strip.gsub(/\s+/, "-")
end

files.each do |filename|
  next unless File.file?(filename)

  content = File.read(filename, encoding: "UTF-8")
  lines = content.lines
  headings = Set.new

  lines.each_with_index do |line, index|
    errors << "#{filename}:#{index + 1}: trailing whitespace" if line.rstrip != line.chomp
    match = line.match(/^[#]{1,6}\s+(.+?)\s*#*\s*$/)
    headings << slug(match[1]) if match
  end

  content.scan(/(?<!!)\[[^\]]*\]\(([^)\s]+)\)/).flatten.each do |target|
    next if target.start_with?("http://", "https://", "mailto:")

    path, fragment = target.split("#", 2)
    if !path.empty? && !File.exist?(File.expand_path(path, File.dirname(filename)))
      errors << "#{filename}: missing relative target #{path}"
    end
    if path.empty? && fragment && !headings.include?(fragment.downcase)
      errors << "#{filename}: missing heading ##{fragment}"
    end
  end
end

if errors.empty?
  puts "Markdown validation passed for #{files.length} file(s)."
  exit 0
end

warn errors.uniq.join("\n")
exit 1
