#!/usr/bin/env ruby
require 'yaml'
require 'xcodeproj'
require 'fileutils'
require 'pp'
require 'plist'
require 'json'

# -------
# Constants
# -------

PROJECT_FILE_NAME='project.yml'
TARGET_FILE='target_information.json'

# -------
# Helpers
# -------
# colorization
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def bold(text); "\e[1m#{text}\e[22m" end

# -------
# Main
# -------

# Load YAML
puts bold "Loading settings from #{PROJECT_FILE_NAME}"
raise red "|- Couldn't find project.yml file" unless File.exist?(PROJECT_FILE_NAME)
project_settings = YAML.load_file(PROJECT_FILE_NAME)

# Load some settings
xcodeproj_path = project_settings['xcodeproj']
configuration = project_settings["configuration"]
PROJECT_ROOT_DIR = File.dirname(xcodeproj_path) + "/"

# Load Xcode project
raise red "|- Couldn't find Xcode project at: #{xcodeproj_path}" unless File.exist?(xcodeproj_path)
project = Xcodeproj::Project.open xcodeproj_path

# Get available targets
available_targets = project.targets.map { |target| target.name }
validated_targets = Hash.new
index = 0

# Validate targets
puts ""
puts bold "Validating target settings"
project_settings["targets"].each_pair { |key, val|

    # Check for target existence
    unless available_targets.include? key
      puts yellow "|- Skipping target #{key}, as Xcode doesn't contain corresponding target."
      next
    end

    # Check if enabled
    unless val["enabled"]
      puts yellow "|- Skipping target #{key}, because it is disabled."
      next
    end

    validated_targets[key] = { "settings" => val, "target" => project.targets[index] }
    index += 1
}

target_information = Hash.new

puts ""
puts bold "Getting target information"

# Get version and build numbers
validated_targets.each_pair { |key, val|

  # Find the correct configuration
  configs = val["target"].build_configurations
  index = configs.index { |x| x.name == configuration }

  # Get info plist
  info_plist = configs[index].build_settings["INFOPLIST_FILE"]
  info_plist_path = PROJECT_ROOT_DIR + info_plist

  plist = Plist.parse_xml info_plist_path
  version = plist["CFBundleShortVersionString"]
  build = plist["CFBundleVersion"]

  puts "|- Target '#{key}' has version #{version} and build number #{build}."

  target_information[key] = {
    "hockey_app_id" => val["settings"]["hockey-app-id"],
    "version" => version,
    "build" => build
  }
}

# Save target info
puts ""
puts bold "Saving target information"
File.open(TARGET_FILE, 'w') { |file|
  file.write(target_information.to_json)
}
puts green "|- Saved succesfully to #{TARGET_FILE}"
