#!/usr/bin/env ruby

# Bring OptionParser into the namespace
require 'optparse'
options = {}
option_parser = OptionParser.new do |opts|
  
  # Create a flag
  opts.on("-b BRAIN") do |brain| 
    options[:brain] = brain
  end
  
  opts.on("-s STATS") do |stats| 
    options[:stats] = stats
  end 
end

option_parser.parse!
puts options.inspect

coord = `fslstats -t #{options[:stats]} -C`.split

basename_brain = File.basename(options[:brain], '.nii.gz')
basename_stats = File.basename(options[:stats], '.nii.gz')
dirname = File.dirname(options[:brain])
lh = {}
rh = {}
axis = ["x", "y", "z"]

(0..2).each do |i|
  lh[axis[i]] = coord[i]
end

(3..5).each do |i|
  rh[axis[i-3]] = coord[i]
end

`fslroi #{options[:brain]} #{dirname}/#{basename_brain}_lh_ax 0 -1 0 -1 #{lh['z']} 1`
`fslroi #{options[:stats]} #{dirname}/#{basename_stats}_lh_ax 0 -1 0 -1 #{lh['z']} 1`
`fslroi #{options[:brain]} #{dirname}/#{basename_brain}_lh_sg #{lh['x']} 1 0 -1 0 -1`
`fslroi #{options[:stats]} #{dirname}/#{basename_stats}_lh_sg #{lh['x']} 1 0 -1 0 -1`
`fslroi #{options[:brain]} #{dirname}/#{basename_brain}_lh_cor 0 -1 #{lh['y']} 1 0 -1`
`fslroi #{options[:stats]} #{dirname}/#{basename_stats}_lh_cor 0 -1 #{lh['y']} 1 0 -1`




#cmd = `du -sh #{brain_file}`
#system(cmd)

