Pod::Spec.new do |spec|
  spec.name = "Nutella"
  spec.version = "1.0.0"
  spec.summary = "Swift for Nutella"
  spec.homepage = "https://github.com/aperritano/Nutella"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Anthony Perritano" => 'aperritano@gmail.com' }
  spec.social_media_url = "https://github.com/aperritano/Nutella"

  spec.platform = :ios, "9.3"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/aperritano/Nutella.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "Nutella/**/*.{h,swift}"
  spec.dependency "MQTTClient"
end
