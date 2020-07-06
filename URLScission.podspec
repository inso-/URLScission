Pod::Spec.new do |spec|
    spec.name                      = "URLScission"
    spec.version                   = "0.0.1"
    spec.summary                   = "URLSession Log and Mock Framework."
    spec.description               = "A Framework to log network call and to mock their results"
    spec.homepage                  = "https://github.com/inso-/URLScission"
    spec.license                   = { :type => 'MIT' }
    spec.author                    = { "Thomas Moussajee" => "thomas.moussajee@gmail.com" }
    spec.source                    = { :git => "/Users/Moussajee/repo/URLScission", :tag => "#{spec.version}" }
    spec.source_files              = "URLScission/**/*.swift"
    spec.swift_version             = "5.0"
    spec.ios.deployment_target     = '10.0'    
end