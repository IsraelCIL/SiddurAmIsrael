#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Registers app-level iOS resources into the committed Runner Xcode project so
# they are bundled at build time. Idempotent — safe to run on every CI build.
# Requires the `xcodeproj` gem (gem install xcodeproj).
#
# Registers:
#   1. ios/Runner/PrivacyInfo.xcprivacy        — zero data collection / required-reason APIs
#   2. ios/Runner/{en,he}.lproj/InfoPlist.strings — localized home-screen app name
#
# These files are committed in the repo; this script only wires them into the
# Xcode project (.pbxproj), which is what makes Xcode copy them into the bundle.

require 'xcodeproj'

PROJECT = 'ios/Runner.xcodeproj'

project = Xcodeproj::Project.open(PROJECT)
target  = project.targets.find { |t| t.name == 'Runner' } or abort('Runner target not found')
group   = project.main_group['Runner'] or abort('Runner group not found')
resources = target.resources_build_phase

def already_in_resources?(phase, display_name)
  phase.files.any? { |bf| bf.display_name == display_name }
end

# 1) Privacy manifest ----------------------------------------------------------
if group.files.any? { |f| f.display_name == 'PrivacyInfo.xcprivacy' }
  puts 'PrivacyInfo.xcprivacy already referenced.'
else
  ref = group.new_reference('PrivacyInfo.xcprivacy') # path resolves to Runner/PrivacyInfo.xcprivacy
  resources.add_file_reference(ref) unless already_in_resources?(resources, 'PrivacyInfo.xcprivacy')
  puts 'Registered PrivacyInfo.xcprivacy.'
end

# 2) Localized app name (InfoPlist.strings: en + he) ---------------------------
project.root_object.known_regions = (project.root_object.known_regions + %w[en he Base]).uniq

if group.children.any? { |c| c.display_name == 'InfoPlist.strings' }
  puts 'InfoPlist.strings variant group already present.'
else
  variant = project.new(Xcodeproj::Project::Object::PBXVariantGroup)
  variant.name = 'InfoPlist.strings'
  variant.source_tree = '<group>'
  group << variant

  { 'en' => 'en.lproj/InfoPlist.strings', 'he' => 'he.lproj/InfoPlist.strings' }.each do |lang, path|
    ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
    ref.name = lang
    ref.path = path
    ref.source_tree = '<group>'
    ref.last_known_file_type = 'text.plist.strings'
    variant << ref
  end

  resources.add_file_reference(variant) unless already_in_resources?(resources, 'InfoPlist.strings')
  puts 'Registered localized InfoPlist.strings (en, he).'
end

project.save
puts 'iOS project configured.'
