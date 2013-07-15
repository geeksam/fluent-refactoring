#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'
require 'grit'

##### Here be a bunch of lets #####

def root
  @root ||= Pathname.new('.')
end

def subject
  @subject ||= root + 'lab/installations_controller.rb'
end

def target
  @target ||= ARGV.shift or raise "No target specified."
end

def target_dir
  root + 'metadata' + target
end

def repo
  @repo ||= Grit::Repo.new(root)
end

def ignored_files
  @ignored_files ||= \
    (Dir[root + 'lab/*'] - [subject.to_s]) \
      .map {|s| s.gsub(/^\/?lab\//, '') }
end

# Find the history of the target commit, up to and including
# where it diverged from master
def history_of_interest
  @history_of_interest ||= \
    begin
      target_ids = repo.commits(target, false).map(&:id_abbrev)
      master_ids = repo.commits('master', false).map(&:id_abbrev)
      common_ancestor = (target_ids & master_ids).first
      history = (target_ids - master_ids) + [common_ancestor]
      history.reverse # start with oldest
    end
end


##### And some side-effect-having helper methods #####

def build_commit_subdir(target_dir, commit_id, index)
  commit = repo.commit(commit_id)
  message = commit.message.downcase.gsub(/\W+/, '-').gsub(/(^\-|\-$)/, '')
  subdir = target_dir + '%02d-%s' % [index, message]
  FileUtils.mkdir_p(subdir)
  subdir
end

def show_files_of_interest_as_of(commit_id, subdir)
  commit = repo.commit(commit_id)
  tree = commit.tree / 'lab'
  tree.contents.each do |blob|
    next if ignored_files.include?(blob.name)
    File.open(subdir + blob.name, 'w') do |f|
      f << blob.data
    end
  end
end

def combine_ruby_files_in(subdir)
  first_post = true
  File.open(subdir + 'combined.rb', 'w') do |combined|
    Dir[subdir + '*.rb'].each do |fname|
      next if fname =~ /combined\.rb/
      if first_post
        first_post = false
      else
        combined << "\n"
      end
      combined << "##### #{File.basename(fname)} #####\n"
      combined << File.read(fname)
    end
  end
end

def generate_syntax_highlighting_in(subdir)
  Dir[subdir + '*.rb'].each do |fname|
    `pygmentize -o #{fname}.rtf #{fname}`
  end
end
