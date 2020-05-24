# -*- ruby -*-

namespace :common_mark do
  desc "Tag"
  task :tag => :environment do
    plugin = Redmine::Plugin.find(:common_mark)
    version = plugin.version
    cd(plugin.directory) do
      sh("git", "tag",
         "-a", "v#{version}",
         "-m", "#{version} has been released!!!")
      sh("git", "push", "--tags")
    end
  end

  desc "Release"
  task :release => :tag
end
