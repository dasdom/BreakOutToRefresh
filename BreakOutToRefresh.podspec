Pod::Spec.new do |s|
  s.name             = "BreakOutToRefresh"
  s.version          = "1.0.0"
  s.summary          = "Play BreakOut while loading - A playable pull to refresh view using SpriteKit"

  s.description      = <<-DESC
  BreakOutToRefresh uses SpriteKit to add a playable mini game to the pull to refresh view in a table view. In this case the mini game is BreakOut but a lot of other mini games could be presented in this space.
                       DESC

  s.homepage         = "https://github.com/dasdom/BreakOutToRefresh"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.author           = { "Dominik Hauser" => "dominik.hauser@dasdom.de" }
  s.source           = { :git => "https://github.com/dasdom/BreakOutToRefresh.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dasdom'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'BreakOutToRefresh/**/*'

  s.frameworks = 'UIKit', 'SpriteKit'
end
