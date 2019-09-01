#!/usr/bin/env ruby

def pratt(source)
  source.to_i
end

if $0 == __FILE__
  puts pratt($stdin.read)
end
