source "https://rubygems.org"

gemspec

gem "rake", "~> 11.0"
gem "gcloud-jsondoc",
    git: "https://github.com/GoogleCloudPlatform/google-cloud-ruby.git",
    branch: "gcloud-jsondoc"

# WORKAROUND: builds are having problems since the release of 3.0.0
# pin to the last known good version
gem "public_suffix", "~> 2.0"

# TEMP: rainbow (a dependency of rubocop) version 2.2 seems to have a problem,
# so pinning to 2.1 for now.
gem "rainbow", "~> 2.1.0"
