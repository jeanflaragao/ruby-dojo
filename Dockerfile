# 1. Pin the exact patch version to match your local host machine perfectly
FROM ruby:3.3.11-slim

# 2. Set a dedicated path for gems so your local volume mount doesn't erase them
# Added BUNDLE_BIN and PATH to ensure executables (like rubocop) are easily found
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    PATH=/usr/local/bundle/bin:$PATH

# 3. Install essential Linux packages
# Added --no-install-recommends to keep the image lightweight
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    pkg-config \
    libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 4. Copy ONLY Gemfiles first
# This is a Docker trick: it caches the bundle install step. 
# It will only re-run bundle install if your Gemfile actually changes.
COPY Gemfile Gemfile.lock ./

# 5. Install gems
RUN bundle install

# 6. Copy the rest of the application
COPY . .

# 7. Default command (starts a bash shell by default instead of irb)
CMD ["bash"]